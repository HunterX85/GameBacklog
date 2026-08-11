//
//  EditGameView.swift
//  GameBacklog
//
//  Created by Serhii Pershuta on 11.08.2026.
//

import SwiftUI
import SwiftData

/// Lets the user change an existing backlog entry's platform and status.
///
/// Unlike `AddGameView`, the title/cover are fixed — there's no re-search,
/// so edits are staged in local `@State` and only written back to the
/// (already-persisted) `Game` when Save is tapped, not on every tap.
struct EditGameView: View {
    let game: Game

    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var selectedPlatform: String
    @State private var status: GameStatus

    init(game: Game) {
        self.game = game
        _selectedPlatform = State(initialValue: game.platform)
        _status = State(initialValue: game.status)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        CoverThumbnail(url: game.coverURL)

                        Text(game.title)
                            .font(.headline)
                            .lineLimit(2)

                        Spacer(minLength: 0)
                    }
                }

                if !game.availablePlatforms.isEmpty {
                    Section {
                        Picker(String(localized: "addGame.field.platform"), selection: $selectedPlatform) {
                            ForEach(game.availablePlatforms, id: \.self) { platform in
                                Text(platform).tag(platform)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }

                Section {
                    Picker(String(localized: "addGame.field.status"), selection: $status) {
                        ForEach(GameStatus.allCases) { status in
                            Text(status.title).tag(status)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle(String(localized: "editGame.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "editGame.button.save")) {
                        save()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "addGame.button.close")) {
                        dismiss()
                    }
                }
            }
        }
    }

    private func save() {
        game.platform = selectedPlatform
        game.status = status
        do {
            try modelContext.save()
        } catch {
            // `game` is a live reference, so this mutation is already visible
            // in the UI even if the persist below fails — surfacing that
            // mismatch loudly in debug beats a silent, confusing data loss.
            assertionFailure("Failed to save game update: \(error)")
        }
        dismiss()
    }
}

#Preview {
    let container = try! ModelContainer(for: Game.self, configurations: .init(isStoredInMemoryOnly: true))
    let game = Game.samples[0]
    container.mainContext.insert(game)

    return EditGameView(game: game)
        .modelContainer(container)
}
