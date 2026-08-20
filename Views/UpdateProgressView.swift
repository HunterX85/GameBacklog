//
//  UpdateProgressView.swift
//  GameBacklog
//
//  Created by Serhii Pershuta on 20.08.2026.
//

import SwiftUI

/// Lets the user drag a slider to set how much of a game they've completed.
///
/// A dedicated sheet rather than a field on `EditGameView` — progress is
/// something people nudge often while actively playing, so it shouldn't
/// require going through the platform/status edit flow to update.
struct UpdateProgressView: View {
    let game: Game

    @EnvironmentObject private var gamesViewModel: GamesViewModel
    @Environment(\.dismiss) var dismiss

    @State private var progress: Double
    @State private var isSaving = false
    @State private var saveError: String?

    init(game: Game) {
        self.game = game
        _progress = State(initialValue: game.progress)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                HStack(spacing: 12) {
                    CoverThumbnail(url: game.coverURL)

                    Text(game.title)
                        .font(.headline)
                        .lineLimit(2)

                    Spacer(minLength: 0)
                }

                VStack(spacing: 16) {
                    Text(progress, format: .percent.precision(.fractionLength(0)))
                        .font(.system(size: 40, weight: .medium))
                        .monospacedDigit()
                        .foregroundStyle(game.status.tint)

                    Slider(value: $progress, in: 0...1, step: 0.01)
                        .tint(game.status.tint)

                    HStack {
                        Text("0%")
                        Spacer()
                        Text("100%")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(20)
            .navigationTitle(String(localized: "updateProgress.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button(String(localized: "editGame.button.save")) {
                            Task { await save() }
                        }
                        .disabled(progress == game.progress)
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

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        let update = Game.Update(platform: game.platform, status: game.status, progress: progress)
        if await gamesViewModel.update(id: game.id, with: update) {
            dismiss()
        } else {
            saveError = gamesViewModel.errorMessage
        }
    }
}

#Preview {
    UpdateProgressView(game: Game.samples[3])
        .environmentObject(GamesViewModel(previewGames: Game.samples))
}
