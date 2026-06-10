//
//  Game.swift
//  GameBacklog
//
//  Created by Serhii Pershuta on 26.05.2026.
//

import Foundation

enum GameStatus: String, CaseIterable {
    case wantToPlay = "Хочу пройти"
    case inProgress = "В прогресі"
    case completed  = "Пройдено"
}

struct Game: Identifiable {
    let id: UUID = UUID()
    var title: String
    var platform: String
    var status: GameStatus
}
