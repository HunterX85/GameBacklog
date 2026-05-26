//
//  ContentView.swift
//  GameBacklog
//
//  Created by Serhii Pershuta on 02.05.2026.
//

import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = GameListViewModel()

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.games) { game in
                    VStack(alignment: .leading) {
                        Text(game.title)
                            .font(.headline)
                        Text(game.platform)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(game.status.rawValue)
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }
                .onDelete(perform: viewModel.deleteGame)
            }
            .navigationTitle("Game Backlog")
        }
    }
}
#Preview {
    ContentView()
}
