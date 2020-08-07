//
//  BoardListCellView.swift
//  LifeGameApp
//
//  Created by Yusuke Hosonuma on 2020/08/06.
//

import SwiftUI
import LifeGame
import Foundation

struct BoardListCellView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var item: BoardDocument
    
    var body: some View {
        HStack() {
            #if os(iOS)
            Image(uiImage: thumbnailImage)
                .antialiased(false)
                .resizable()
                .frame(width: 44, height: 44, alignment: .center)
            #endif
            Text("\(item.title)")
            Spacer()
        }
    }
    
    private var fillColor: CGColor {
        colorScheme == .dark
            ? CGColor(red: 1, green: 1, blue: 1, alpha: 1)
            : CGColor(red: 0, green: 0, blue: 0, alpha: 1)
    }
    
    // Note:
    // レンダリングコストが高ければバックグラウンド処理を検討する。
    // （たかが数百ピクセルなので大したこと無い・・・はず）
    #if os(iOS)
    private var thumbnailImage: UIImage {
        let board = LifeGameBoard(size: item.size, cells: item.cells)
        
        let scale = 4
        let size = CGSize(width: item.size * scale, height: item.size * scale)
        
        return UIGraphicsImageRenderer(size: size)
            .image(actions: { context in
                context.cgContext.setFillColor(fillColor)
                
                for (index, cell) in board.cells.enumerated() {
                    let x = (index % item.size) * scale
                    let y = (index / item.size) * scale
                    if cell == .alive {
                        context.fill(CGRect(origin: CGPoint(x: x, y: y), size: CGSize(width: scale, height: scale)))
                    }
                }
            })
    }
    #endif
}

struct BoardListCellView_Previews: PreviewProvider {

    static var previews: some View {
        view(title: "Nebura", board: BoardPreset.nebura.board, colorScheme: .light)
        view(title: "Nebura", board: BoardPreset.nebura.board, colorScheme: .dark)
        view(title: "SpaceShip", board: BoardPreset.spaceShip.board, colorScheme: .dark)
    }
    
    @ViewBuilder
    private static func view(title: String, board: LifeGameBoard, colorScheme: ColorScheme) -> some View {
        BoardListCellView(
            item: BoardDocument(id: nil,
                                title: title,
                                size: board.size,
                                cells: board.cells.map(\.rawValue))
        )
        .previewLayout(.sizeThatFits)
        .preferredColorScheme(colorScheme)
    }
}