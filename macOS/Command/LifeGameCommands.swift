//
//  LifeGameCommands.swift
//  LifeGameApp (macOS)
//
//  Created by Yusuke Hosonuma on 2020/07/28.
//

import SwiftUI
import LifeGame
import UniformTypeIdentifiers

struct LifeGameCommands: Commands {    
    @ObservedObject var viewModel: MainGameViewModel
    @ObservedObject var boardRepository: FirestoreBoardRepository

    // TODO: beta4 bug (maybe...)❗
    // Not update disabled state when viewModel was changed.
    
    var body: some Commands {
        CommandGroup(before: .saveItem) {
            Section {
                Button("Save", action: save)
                Button("Open...", action: open)
            }
            Section {
                Button("Export Presets...", action: exportPresets)
            }
        }
        
        CommandMenu("Game") {
            Section {
                Button("Start", action: viewModel.tapPlayButton)
                    .keyboardShortcut("r")
                    .disabled(viewModel.playButtonDisabled)
                
                Button("Stop", action: viewModel.tapStopButton)
                    .keyboardShortcut("x")
                    .disabled(viewModel.stopButtonDisabled)
                
                Button("Next", action: viewModel.tapNextButton)
                    .keyboardShortcut("n") // Next `s`tep
                    .disabled(viewModel.nextButtonDisabled)
            }
            
            // TODO: Don't apply section... beta3 bug?

            Section {
                Button("Clear", action: viewModel.tapClear)
                    .keyboardShortcut("k", modifiers: [.command, .shift])
            }
        }
    }
    
    // MARK: Actions
    
    private func save() {
        let panel = NSSavePanel()
        panel.directoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        panel.canCreateDirectories = true
        panel.showsTagField = true
        panel.nameFieldStringValue = "Untitled"
        panel.allowedContentTypes = [UTType(exportedAs: "tech.penginmura.LifeGameApp.board")]

        if panel.runModal() == .OK {
            guard let url = panel.url else { fatalError() }
            do {
                let data = try JSONEncoder().encode(viewModel.board.board)
                try data.write(to: url)
            } catch {
                fatalError("Failed to write file: \(error.localizedDescription)")
            }
        }
    }
    
    private func open() {
        let panel = NSOpenPanel()
        panel.directoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        panel.canCreateDirectories = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [UTType(exportedAs: "tech.penginmura.LifeGameApp.board")]

        if panel.runModal() == .OK {
            guard let url = panel.url else { fatalError() }
            do {
                let data = try Data(contentsOf: url)
                let board = try JSONDecoder().decode(Board<Cell>.self, from: data)
                viewModel.loadBoard(board)
            } catch {
                fatalError("Failed to read file: \(error.localizedDescription)")
            }
        }
    }
    
    private func exportPresets() {
        let panel = NSSavePanel()
        panel.directoryURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        panel.canCreateDirectories = true
        panel.showsTagField = true
        panel.nameFieldStringValue = "LifeGamePresets"
        panel.allowedContentTypes = [UTType.json]
        
        if panel.runModal() == .OK {
            guard let url = panel.url else { fatalError() } // 複数選択でなければ発生しないらしい
            
            let items = boardRepository.items.map(BoardPresetFile.init)
            do {
                let encoder = JSONEncoder()
                let data = try encoder.encode(items)
                try data.write(to: url)
            } catch {
                fatalError("Failed to write file: \(error.localizedDescription)")
            }
        }
    }
}
