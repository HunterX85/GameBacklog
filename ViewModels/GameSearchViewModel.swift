//
//  GameSearchViewModel.swift
//  GameBacklog
//
//  Created by Serhii Pershuta on 10.08.2026.
//

import Foundation
import Combine

/// Debounced IGDB title search backing the suggestion dropdown in `AddGameView`.
///
/// Driven by a `.task(id: query)` in the view: SwiftUI cancels the previous
/// task automatically whenever the query changes, so `search()` doesn't need
/// to track in-flight work itself — it just needs to bail out via
/// `Task.isCancelled` after the debounce sleep and after the network call.
@MainActor
final class GameSearchViewModel: ObservableObject {
    @Published var query = ""
    @Published private(set) var results: [IGDBGame] = []
    @Published private(set) var isSearching = false
    @Published private(set) var hasError = false

    /// Below this length we stay idle — short prefixes return too much noise
    /// to be useful and would burn through IGDB's rate limit for nothing.
    static let minimumQueryLength = 2
    private static let debounceNanoseconds: UInt64 = 300_000_000
    private static let resultLimit = 20

    private let service: IGDBService?

    init(service: IGDBService? = IGDBService.shared) {
        self.service = service
    }

    func search() async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= Self.minimumQueryLength else {
            isSearching = false
            results = []
            hasError = false
            return
        }
        guard let service else {
            isSearching = false
            results = []
            hasError = true
            return
        }

        try? await Task.sleep(nanoseconds: Self.debounceNanoseconds)
        guard !Task.isCancelled else { return }

        isSearching = true
        hasError = false

        do {
            let games = try await service.searchGames(query: trimmed, limit: Self.resultLimit)
            guard !Task.isCancelled else { return }
            results = games
            isSearching = false
        } catch {
            guard !Task.isCancelled else { return }
            results = []
            hasError = true
            isSearching = false
        }
    }

    func reset() {
        query = ""
        results = []
        isSearching = false
        hasError = false
    }
}
