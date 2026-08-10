//
//  AddGameView.swift
//  GameBacklog
//
//  Created by Serhii Pershuta on 10.06.2026.
//

import SwiftUI

struct AddGameView: View {
    @ObservedObject var viewModel: GameListViewModel
    @Environment(\.dismiss) var dismiss

    @State private var title = ""
    @State private var platform = ""
    @State private var status: GameStatus = .backlog

    var body: some View {
        NavigationStack {
            Form {
                TextField(String(localized: "addGame.field.gameTitle"), text: $title)
                TextField(String(localized: "addGame.field.platform"), text: $platform)

                Picker(String(localized: "addGame.field.status"), selection: $status) {
                    ForEach(GameStatus.allCases) { status in
                        Text(status.title).tag(status)
                    }
                }
                .pickerStyle(.menu)
            }
            .navigationTitle(String(localized: "addGame.title"))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "addGame.button.add")) {
                        viewModel.addGame(title: title, platform: platform, status: status)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "addGame.button.close")) {
                        dismiss()
                    }
                }
            }
        }
    }
}
