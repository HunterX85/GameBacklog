//
//  Game.swift
//  GameBacklog
//
//  Created by Serhii Pershuta on 26.05.2026.
//

import SwiftUI
import SwiftData

/// Lifecycle state of a game in the user's backlog.
///
/// Each case carries its own presentation metadata (title, accent colour and
/// SF Symbol) so the UI layer never has to `switch` over the status to render it.
enum GameStatus: String, Codable, CaseIterable, Identifiable {
    case backlog
    case playing
    case completed
    case dropped

    var id: String { rawValue }

    var title: String {
        switch self {
        case .backlog:   String(localized: "status.backlog")
        case .playing:   String(localized: "status.playing")
        case .completed: String(localized: "status.completed")
        case .dropped:   String(localized: "status.dropped")
        }
    }

    /// Accent colour used for the status badge and the progress bar fill.
    var tint: Color {
        switch self {
        case .backlog:   .blue
        case .playing:   .orange
        case .completed: .green
        case .dropped:   .gray
        }
    }

    /// SF Symbol shown next to the activity caption on a card.
    var activitySymbol: String {
        self == .playing ? "clock" : "calendar"
    }

    /// Dropped games have no meaningful completion progress to display.
    var showsProgress: Bool { self != .dropped }
}

@Model
final class Game {
    var title: String
    var platform: String
    var status: GameStatus
    /// Completion ratio in the `0...1` range, surfaced as a progress bar.
    var progress: Double
    /// Human-readable activity caption, e.g. "Completed 3 days ago".
    var activity: String
    /// Cover art fetched from IGDB at add time, if available.
    var coverURL: URL?
    /// Drives sort order in `@Query` — insertion order isn't otherwise guaranteed.
    var dateAdded: Date

    init(
        title: String,
        platform: String,
        status: GameStatus,
        progress: Double = 0,
        activity: String = "",
        coverURL: URL? = nil,
        dateAdded: Date = .now
    ) {
        self.title = title
        self.platform = platform
        self.status = status
        self.progress = progress
        self.activity = activity
        self.coverURL = coverURL
        self.dateAdded = dateAdded
    }
}

// MARK: - Preview data

extension Game {
    /// Sample backlog for previews only — the app starts empty at runtime.
    static var samples: [Game] {
        [
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
}
