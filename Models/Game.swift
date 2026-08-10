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
enum GameStatus: String, CaseIterable, Identifiable {
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

struct Game: Identifiable {
    let id = UUID()
    var title: String
    var platform: String
    var status: GameStatus
    /// Completion ratio in the `0...1` range, surfaced as a progress bar.
    var progress: Double = 0
    /// Human-readable activity caption, e.g. "Completed 3 days ago".
    var activity: String = ""
}
