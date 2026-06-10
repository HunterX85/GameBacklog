//
//  ContentView.swift
//  GameBacklog
//
//  Created by Serhii Pershuta on 02.05.2026.
//

import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = GameListViewModel()
    @State private var showingAddGame = false

    var body: some View {
        TabView {
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
                .navigationTitle(String(localized: "app.title"))
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showingAddGame = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
                .sheet(isPresented: $showingAddGame) {
                    AddGameView(viewModel: viewModel)
                }
            }
            .tabItem {
                Label(String(localized: "tab.games"), systemImage: "gamecontroller")
            }

            NavigationStack {
                ProfileScreenView()
            }
            .tabItem {
                Label(String(localized: "tab.profile"), systemImage: "person")
            }

            NavigationStack {
                Text(String(localized: "tab.settings"))
                    .navigationTitle(String(localized: "tab.settings"))
            }
            .tabItem {
                Label(String(localized: "tab.settings"), systemImage: "gearshape")
            }
        }
    }
}

#Preview {
    ContentView()
}
