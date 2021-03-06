//
//  SignInButton.swift
//  LifeGameApp
//
//  Created by Yusuke Hosonuma on 2020/08/23.
//

import AuthenticationServices
import SwiftUI
import os
import FirebaseAuth
import CryptoKit

private let logger = Logger(subsystem: "LifeGameApp", category: "SignInView")

struct SignInButton: View {
    @Binding private var inProgress: Bool
    private let completion: (Error?) -> Void

    @State private var currentNonce: String?
    
    init(inProgress: Binding<Bool>, completion: @escaping (Error?) -> Void) {
        _inProgress = inProgress
        self.completion = completion
    }
    
    var body: some View {
        SignInWithAppleButton(.signIn, onRequest: onRequest, onCompletion: onCompletion)
    }
    
    // MARK: Private
    
    private func onRequest(request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        currentNonce = nonce
        request.nonce = sha256(nonce)
        
        // Note:
        // とりあえず今は何も取得しない。
        // request.requestedScopes = [.fullName, .email]
    }
    
    private func onCompletion(result: Result<ASAuthorization, Error>) {
        switch result {
        case let .success(authorization):
            self.signIn(authorization: authorization)
            
        case let .failure(error):
            logger.notice("Sign in with Apple is failed. - \(error.localizedDescription)")
        }
    }

    private func signIn(authorization: ASAuthorization) {
        inProgress = true
        
        // TODO: エラー処理は細かく精査してないので、とりあえず`fatalError`にして失敗した時にすぐに気付けるようにしておく。
        
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            fatalError()
        }
        
        guard let nonce = currentNonce else {
            logger.fault("Invalid state: A login callback was received, but no login request was sent.")
            fatalError()
        }
        
        guard let appleIDToken = appleIDCredential.identityToken else {
            logger.error("Unable to fetch identity token")
            fatalError()
        }
        
        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            logger.error("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
            fatalError()
        }

        let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                  idToken: idTokenString,
                                                  rawNonce: nonce)

        Auth.auth().signIn(with: credential) { (authResult, error) in
            inProgress = false

            if let error = error as NSError? {
                logger.error("Firebase sign-in is failure. - \(error.localizedDescription)")
                completion(error)
            } else {
                completion(nil)
            }
        }
    }
}

struct SignInButton_Previews: PreviewProvider {
    static var previews: some View {
        SignInButton(inProgress: .constant(false), completion: { _ in })
    }
}

// MARK: - Functions

// Adapted from https://auth0.com/docs/api-auth/tutorials/nonce#generate-a-cryptographically-random-nonce
private func randomNonceString(length: Int = 32) -> String {
    precondition(length > 0)
    let charset: Array<Character> =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    var result = ""
    var remainingLength = length
    
    while remainingLength > 0 {
        let randoms: [UInt8] = (0 ..< 16).map { _ in
            var random: UInt8 = 0
            let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
            if errorCode != errSecSuccess {
                fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
            }
            return random
        }
        
        randoms.forEach { random in
            if remainingLength == 0 {
                return
            }
            
            if random < charset.count {
                result.append(charset[Int(random)])
                remainingLength -= 1
            }
        }
    }
    
    return result
}

private func sha256(_ input: String) -> String {
    let inputData = Data(input.utf8)
    let hashedData = SHA256.hash(data: inputData)
    let hashString = hashedData.compactMap {
        return String(format: "%02x", $0)
    }.joined()
    
    return hashString
}
