//
//  GamesViewModel.swift
//  GameBacklog
//
//  Created by Serhii Pershuta on 12.08.2026.
//

import Combine
import Foundation

@MainActor
final class GamesViewModel: ObservableObject {
    @Published private(set) var games: [Game] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    /// Distinguishes the very first load from a later pull-to-refresh, so the
    /// view only swaps in a full-screen spinner once. Re-showing it during a
    /// `.refreshable` gesture would restructure the scroll content mid-refresh,
    /// which is exactly what makes SwiftUI cancel the refresh Task.
    @Published private(set) var hasLoadedOnce = false

    private let repository: GamesRepository

    init(repository: GamesRepository) {
        self.repository = repository
    }

    convenience init() {
        self.init(repository: .shared)
    }

    /// For previews/tests — seeds `games` directly and never touches the network.
    init(previewGames: [Game]) {
        self.repository = GamesRepository(client: nil)
        self.games = previewGames
    }

    /// Skips the fetch if games are already loaded, so returning to the Games
    /// tab (which re-triggers `.task` since the view is torn down on every
    /// tab switch) doesn't flicker in a redundant reload. Use `load()`
    /// directly for an explicit refresh (e.g. pull-to-refresh).
    func loadIfNeeded() async {
        guard games.isEmpty, !isLoading else { return }
        await load()
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer {
            isLoading = false
            hasLoadedOnce = true
        }
        do {
            games = try await repository.fetchAll()
        } catch is CancellationError {
            // The refresh was interrupted (e.g. `.refreshable` ended the
            // gesture, or the view was torn down mid-fetch) — not a real
            // failure, so there's nothing worth showing the user.
        } catch GamesRepository.RepositoryError.notConfigured {
            // Unconfigured Supabase client — previews rely on this being silent.
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @discardableResult
    func add(_ draft: Game.Draft) async -> Bool {
        errorMessage = nil
        do {
            let game = try await repository.insert(draft)
            games.append(game)
            return true
        } catch is CancellationError {
            return false
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    @discardableResult
    func update(id: UUID, with update: Game.Update) async -> Bool {
        errorMessage = nil
        do {
            let updated = try await repository.update(id: id, with: update)
            if let index = games.firstIndex(where: { $0.id == id }) {
                games[index] = updated
            }
            return true
        } catch is CancellationError {
            return false
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func delete(id: UUID) async {
        errorMessage = nil
        do {
            try await repository.delete(id: id)
            games.removeAll { $0.id == id }
        } catch is CancellationError {
            // Not a real failure — see `load()`.
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
