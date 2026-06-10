//
//  GameListViewModel.swift
//  GameBacklog
//
//  Created by Serhii Pershuta on 26.05.2026.
//

import Foundation
import Combine
import SwiftUI

class GameListViewModel: ObservableObject {
    @Published var games: [Game] = [
        Game(title: "Witcher 3", platform: "PC", status: .completed),
        Game(title: "GTA 6", platform: "PS5", status: .wantToPlay)
    ]

    func addGame(title: String, platform: String, status: GameStatus) {
        let newGame = Game(title: title, platform: platform, status: status)
        games.append(newGame)
    }

    func deleteGame(at offsets: IndexSet) {
        games.remove(atOffsets: offsets)
    }
}
