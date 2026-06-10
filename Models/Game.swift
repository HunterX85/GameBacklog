//
//  Game.swift
//  GameBacklog
//
//  Created by Serhii Pershuta on 26.05.2026.
//

import Foundation

enum GameStatus: String, CaseIterable {
    case wantToPlay = "Want to Play"
    case inProgress = "In Progress"
    case completed  = "Completed"
}

struct Game: Identifiable {
    let id: UUID = UUID()
    var title: String
    var platform: String
    var status: GameStatus
}
