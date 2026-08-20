//
//  EditGameView.swift
//  GameBacklog
//
//  Created by Serhii Pershuta on 11.08.2026.
//

import SwiftUI

/// Lets the user change an existing backlog entry's platform and status.
///
/// Unlike `AddGameView`, the title/cover are fixed — there's no re-search,
/// so edits are staged in local `@State` and only written back through
/// `GamesViewModel` when Save is tapped, not on every tap. `game` is a value
/// snapshot, not a live reference, so this view never mutates it directly.
struct EditGameView: View {
    let game: Game

    @EnvironmentObject private var gamesViewModel: GamesViewModel
    @Environment(\.dismiss) var dismiss

    @State private var selectedPlatform: String
    @State private var status: GameStatus
    @State private var isSaving = false
    @State private var saveError: String?

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
                    if isSaving {
                        ProgressView()
                    } else {
                        Button(String(localized: "editGame.button.save")) {
                            Task { await save() }
                        }
                        .disabled(!hasChanges)
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "addGame.button.close")) {
                        dismiss()
                    }
                }
            }
        }
        .alert(String(localized: "addGame.save.errorTitle"), isPresented: saveErrorPresented) {
            Button(String(localized: "profile.button.ok"), role: .cancel) {}
        } message: {
            Text(saveError ?? "")
        }
    }

    private var saveErrorPresented: Binding<Bool> {
        Binding(get: { saveError != nil }, set: { if !$0 { saveError = nil } })
    }

    private var hasChanges: Bool {
        selectedPlatform != game.platform || status != game.status
    }

    private func save() async {
        // Nothing changed — skip the round trip rather than firing a no-op PATCH.
        guard hasChanges else {
            dismiss()
            return
        }
        isSaving = true
        defer { isSaving = false }
        let update = Game.Update(platform: selectedPlatform, status: status, progress: game.progress)
        if await gamesViewModel.update(id: game.id, with: update) {
            dismiss()
        } else {
            saveError = gamesViewModel.errorMessage
        }
    }
}

#Preview {
    EditGameView(game: Game.samples[0])
        .environmentObject(GamesViewModel(previewGames: Game.samples))
}
