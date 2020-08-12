//
//  LifeGameWidget.swift
//  LifeGameWidget
//
//  Created by Yusuke Hosonuma on 2020/08/11.
//

import WidgetKit
import SwiftUI
import LifeGame
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> LifeGameEntry {
        let data = LifeGameData(title: "Title", board: Board(size: 12, cell: Cell.die))
        return LifeGameEntry(date: Date(), relevance: data)
    }

    func getSnapshot(in context: Context, completion: @escaping (LifeGameEntry) -> ()) {
        let preset = BoardPreset.nebura
        let data = LifeGameData(title: preset.displayText, board: preset.board.board)
        let entry = LifeGameEntry(date: Date(), relevance: data)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LifeGameEntry>) -> ()) {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        
        FirestoreBoardRepository.shared
            .getAll { documents in
                var entries: [LifeGameEntry] = []

                let currentDate = Date()
                for hourOffset in 0 ..< 5 {
                    // とりあえず分単位で更新
                    let entryDate = Calendar.current.date(byAdding: .minute, value: hourOffset, to: currentDate)!
                    
                    // とりあえずランダムでチョイスするだけ
                    let document = documents.randomElement()!
                    let data = LifeGameData(title: document.title, board: document.makeBoard().extended(by: .die), url: URL(string: "board:///\(document.id!)")!)
                    let entry = LifeGameEntry(date: entryDate, relevance: data)
                    entries.append(entry)
                }

                let timeline = Timeline(entries: entries, policy: .atEnd)
                completion(timeline)
            }
    }
}

struct LifeGameEntry: TimelineEntry {
    var date: Date
    let relevance: LifeGameData
}

struct LifeGameData {
    var title: String
    var board: Board<Cell>
    var url: URL = URL(string: "board:///0")!
}

struct LifeGameWidgetEntryView : View {
    @Environment(\.colorScheme) private var colorScheme
    
    var entry: Provider.Entry

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                BoardThumbnailImage(board: entry.relevance.board, cellColor: cellColor)
                Text(entry.relevance.title)
                    .font(.system(.footnote, design: .monospaced))
                    .foregroundColor(.gray)
            }
            .widgetURL(entry.relevance.url)
            Spacer()
        }
        .padding()
    }
    
    var cellColor: Color {
        switch colorScheme {
        case .light: return UserDefaultSettingGroup.shared.lightModeColor
        case .dark:  return UserDefaultSettingGroup.shared.darkModeColor
        @unknown default:
            fatalError()
        }
    }
}

@main
struct LifeGameWidget: Widget {
    let kind: String = "LifeGameWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            LifeGameWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Random boards")
        .description("Enjoy random boards on Home screen.")
        .supportedFamilies([.systemSmall]) // とりあえず Small のみ
    }
}

struct LifeGameWidget_Previews: PreviewProvider {
    static let preset = BoardPreset.nebura
    static let entry = LifeGameEntry(date: Date(),
                                     relevance: LifeGameData(title: preset.displayText, board: preset.board.board))
    
    static var previews: some View {
        view(colorScheme: .light)
        view(colorScheme: .dark)
    }
    
    static func view(colorScheme: ColorScheme) -> some View {
        LifeGameWidgetEntryView(entry: entry)
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            // Dark is not work in beta 4❗
            .colorScheme(colorScheme)
            .preferredColorScheme(colorScheme)
    }
}