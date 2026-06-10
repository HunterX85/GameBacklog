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
    @State private var status: GameStatus = .wantToPlay

    var body: some View {
        NavigationStack {
            Form {
                TextField("Назва гри", text: $title)
                TextField("Платформа (PC, PS5...)", text: $platform)

                Picker("Статус", selection: $status) {
                    ForEach(GameStatus.allCases, id: \.self) { status in
                        Text(status.rawValue)
                    }
                }
            }
            .navigationTitle("Нова гра")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Додати") {
                        viewModel.addGame(title: title, platform: platform, status: status)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Відміна") {
                        dismiss()
                    }
                }
            }
        }
    }
}
