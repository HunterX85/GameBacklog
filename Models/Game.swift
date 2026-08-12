//
//  Game.swift
//  GameBacklog
//
//  Created by Serhii Pershuta on 26.05.2026.
//

import SwiftUI

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

/// A backlog entry, mirroring a row in Supabase's `games` table.
///
/// Value type by design: mutations go through `GamesViewModel`, which owns
/// the source of truth and pushes updates to Supabase, rather than editing a
/// shared reference in place (the old SwiftData `@Model` pattern).
struct Game: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var platform: String
    var status: GameStatus
    /// Completion ratio in the `0...1` range, surfaced as a progress bar.
    var progress: Double
    /// Human-readable activity caption, e.g. "Completed 3 days ago".
    var activity: String
    /// Cover art fetched from IGDB at add time, if available.
    var coverURL: URL?
    /// Drives sort order — insertion order isn't otherwise guaranteed.
    var dateAdded: Date
    /// Every platform IGDB listed for this title at add time, so the edit
    /// screen can offer the same picker without a second network round trip.
    var availablePlatforms: [String]

    enum CodingKeys: String, CodingKey {
        case id, title, platform, status, progress, activity
        case coverURL = "cover_url"
        case dateAdded = "date_added"
        case availablePlatforms = "available_platforms"
    }
}

// MARK: - Write payloads

extension Game {
    /// Fields sent when creating a game. `id`, `user_id` and `date_added` are
    /// all filled in by Postgres column defaults.
    struct Draft: Encodable {
        var title: String
        var platform: String
        var status: GameStatus
        var progress: Double
        var activity: String
        var coverURL: URL?
        var availablePlatforms: [String]

        enum CodingKeys: String, CodingKey {
            case title, platform, status, progress, activity
            case coverURL = "cover_url"
            case availablePlatforms = "available_platforms"
        }
    }

    /// Fields the edit screen can change — title/cover/progress aren't
    /// editable there yet, so there's nothing to send for them.
    struct Update: Encodable {
        var platform: String
        var status: GameStatus
    }
}

// MARK: - Preview data

extension Game {
    /// Sample backlog for previews only — the app starts empty at runtime.
    static var samples: [Game] {
        [
            Game(id: UUID(), title: "The Witcher 3: Wild Hunt", platform: "PC",
                 status: .completed, progress: 1.0, activity: "Completed 3 days ago",
                 coverURL: nil, dateAdded: .now, availablePlatforms: []),
            Game(id: UUID(), title: "GTA 6", platform: "PS5",
                 status: .backlog, progress: 0.0, activity: "Added 2 days ago",
                 coverURL: nil, dateAdded: .now, availablePlatforms: []),
            Game(id: UUID(), title: "Mafia: Definitive Edition", platform: "PS5",
                 status: .backlog, progress: 0.0, activity: "Added 1 week ago",
                 coverURL: nil, dateAdded: .now, availablePlatforms: []),
            Game(id: UUID(), title: "Red Dead Redemption 2", platform: "PC",
                 status: .playing, progress: 0.46, activity: "Played 25h",
                 coverURL: nil, dateAdded: .now, availablePlatforms: []),
            Game(id: UUID(), title: "Cyberpunk 2077", platform: "PC",
                 status: .dropped, progress: 0.18, activity: "Dropped 2 months ago",
                 coverURL: nil, dateAdded: .now, availablePlatforms: [])
        ]
    }
}
