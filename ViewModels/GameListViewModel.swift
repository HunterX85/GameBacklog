//
//  GameListViewModel.swift
//  GameBacklog
//
//  Created by Serhii Pershuta on 26.05.2026.
//

import Foundation
import Combine
import SwiftUI

/// Top-level filter shown as a segmented control on the Games screen.
enum GameFilter: String, CaseIterable, Identifiable {
    case all
    case backlog
    case playing
    case completed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:       String(localized: "filter.all")
        case .backlog:   String(localized: "filter.backlog")
        case .playing:   String(localized: "filter.playing")
        case .completed: String(localized: "filter.completed")
        }
    }

    /// Status this filter maps to, or `nil` for the catch-all `.all` case.
    var matchingStatus: GameStatus? {
        switch self {
        case .all:       nil
        case .backlog:   .backlog
        case .playing:   .playing
        case .completed: .completed
        }
    }
}

final class GameListViewModel: ObservableObject {
    @Published var games: [Game]
    @Published var filter: GameFilter = .all

    init(games: [Game] = GameListViewModel.sampleGames) {
        self.games = games
    }

    // MARK: Derived state

    /// Games matching the currently selected filter, preserving insertion order.
    var filteredGames: [Game] {
        guard let status = filter.matchingStatus else { return games }
        return games.filter { $0.status == status }
    }

    var totalCount: Int { games.count }

    var completedCount: Int {
        games.lazy.filter { $0.status == .completed }.count
    }

    // MARK: Mutations

    func addGame(title: String, platform: String, status: GameStatus) {
        let game = Game(
            title: title,
            platform: platform,
            status: status,
            progress: status == .completed ? 1 : 0,
            activity: String(localized: "activity.justAdded")
        )
        games.append(game)
    }

    func deleteGame(at offsets: IndexSet) {
        games.remove(atOffsets: offsets)
    }
}

// MARK: - Placeholder data

extension GameListViewModel {
    /// Sample backlog used while the app has no persistence layer yet.
    static let sampleGames: [Game] = [
        Game(title: "The Witcher 3: Wild Hunt", platform: "PC",
             status: .completed, progress: 1.0, activity: "Completed 3 days ago"),
        Game(title: "GTA 6", platform: "PS5",
             status: .backlog, progress: 0.0, activity: "Added 2 days ago"),
        Game(title: "Mafia: Definitive Edition", platform: "PS5",
             status: .backlog, progress: 0.0, activity: "Added 1 week ago"),
        Game(title: "Red Dead Redemption 2", platform: "PC",
             status: .playing, progress: 0.46, activity: "Played 25h"),
        Game(title: "Cyberpunk 2077", platform: "PC",
             status: .dropped, progress: 0.18, activity: "Dropped 2 months ago")
    ]
}
