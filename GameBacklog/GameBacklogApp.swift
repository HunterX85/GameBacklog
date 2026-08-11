//
//  GameBacklogApp.swift
//  GameBacklog
//
//  Created by Serhii Pershuta on 02.05.2026.
//

import SwiftUI
import SwiftData

@main
struct GameBacklogApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Game.self)
    }
}
