//
//  BacklogExport.swift
//  GameBacklog
//
//  Created by Serhii Pershuta on 12.08.2026.
//

import Foundation

/// Portable JSON snapshot of a user's backlog, written by the Settings screen's
/// export flow and read back by its import flow.
///
/// Deliberately excludes `id`/`dateAdded`: importing always creates fresh rows
/// rather than trying to reproduce another device's identifiers, so a file can
/// be imported repeatedly (or into a different account) without conflicts.
struct BacklogExport: Codable {
    static let currentVersion = 1

    var version: Int
    var exportedAt: Date
    var games: [Entry]

    init(games: [Game], exportedAt: Date = .now) {
        self.version = Self.currentVersion
        self.exportedAt = exportedAt
        self.games = games.map(Entry.init)
    }

    struct Entry: Codable {
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

        init(_ game: Game) {
            title = game.title
            platform = game.platform
            status = game.status
            progress = game.progress
            activity = game.activity
            coverURL = game.coverURL
            availablePlatforms = game.availablePlatforms
        }

        /// Insert payload for `GamesRepository` — every imported game lands
        /// in the backlog as a brand-new row.
        var draft: Game.Draft {
            Game.Draft(
                title: title,
                platform: platform,
                status: status,
                progress: progress,
                activity: activity,
                coverURL: coverURL,
                availablePlatforms: availablePlatforms
            )
        }
    }
}
