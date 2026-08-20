//
//  GameBacklogApp.swift
//  GameBacklog
//
//  Created by Serhii Pershuta on 02.05.2026.
//

import Auth
import Supabase
import SwiftUI

@main
struct GameBacklogApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    guard let client = SupabaseClientProvider.shared else { return }
                    Task { try? await client.auth.session(from: url) }
                }
        }
    }
}
