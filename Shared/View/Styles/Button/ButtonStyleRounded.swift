//
//  RoundStyle.swift
//  LifeGameApp
//
//  Created by Yusuke Hosonuma on 2020/07/16.
//

import SwiftUI

struct ButtonStyleRounded: ButtonStyle {
    var color: Color = .accentColor
    
    func makeBody(configuration: Configuration) -> some View {
        Button(color: color, configuration: configuration)
    }
    
    struct Button: View {
        var color: Color
        var configuration: Configuration
        
        @Environment(\.isEnabled) private var isEnabled: Bool
        @Environment(\.colorScheme) private var colorScheme: ColorScheme
        
        var foregroundColor: Color {
            color.opacity(!isEnabled ? 0.5 : configuration.isPressed ? 0.8 : 1.0)
        }
        
        var body: some View {
            RoundedRectangle(cornerRadius: 8)
                .fill(BackgroundStyle())
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(foregroundColor))
                .overlay(configuration.label.foregroundColor(foregroundColor))
                .frame(width: 90, height: 40)
        }
    }
}

struct ButtonStyleRound_Previews: PreviewProvider {
    
    struct PreviewView: View {
        var body: some View {
            HStack {
                Button("Start") {}
                    .buttonStyle(ButtonStyleRounded())
                Button("Stop") {}
                    .buttonStyle(ButtonStyleRounded())
                    .disabled(true)
                Button("Cancel") {}
                    .buttonStyle(ButtonStyleRounded(color: .red))
            }
            .padding()
            .previewLayout(.sizeThatFits)
        }
    }

    static var previews: some View {
        Group {
            PreviewView()
                .preferredColorScheme(.light)
            PreviewView()
                .preferredColorScheme(.dark)
        }
    }
}
