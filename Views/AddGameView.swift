//
//  AddGameView.swift
//  GameBacklog
//
//  Created by Serhii Pershuta on 10.06.2026.
//

import SwiftUI
import SwiftData

struct AddGameView: View {
    @StateObject private var search = GameSearchViewModel()
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @FocusState private var searchFieldFocused: Bool

    @State private var selectedGame: IGDBGame?
    @State private var selectedPlatform: String = ""
    @State private var status: GameStatus = .backlog

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if selectedGame == nil {
                    searchField
                }

                if let selectedGame {
                    selectedGameDetails(selectedGame)
                } else {
                    suggestions
                }
            }
            .padding(.top, 12)
            .background(Color(.systemGroupedBackground))
            .navigationTitle(String(localized: "addGame.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "addGame.button.add")) {
                        addGame()
                    }
                    .disabled(selectedGame == nil)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "addGame.button.close")) {
                        dismiss()
                    }
                }
            }
        }
        .task(id: search.query) {
            await search.search()
        }
        .onAppear { searchFieldFocused = true }
    }

    // MARK: Search field

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField(String(localized: "addGame.search.placeholder"), text: $search.query)
                .focused($searchFieldFocused)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()

            if !search.query.isEmpty {
                Button {
                    search.reset()
                    searchFieldFocused = true
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal, 16)
    }

    // MARK: Suggestions dropdown

    @ViewBuilder
    private var suggestions: some View {
        let trimmed = search.query.trimmingCharacters(in: .whitespacesAndNewlines)

        if search.isSearching {
            statusRow(String(localized: "addGame.search.searching"))
            Spacer(minLength: 0)
        } else if search.hasError {
            statusRow(String(localized: "addGame.search.error"))
            Spacer(minLength: 0)
        } else if trimmed.count >= GameSearchViewModel.minimumQueryLength && search.results.isEmpty {
            statusRow(String(localized: "addGame.search.noResults"))
            Spacer(minLength: 0)
        } else if !search.results.isEmpty {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(search.results) { game in
                        Button {
                            select(game)
                        } label: {
                            SearchResultRow(game: game)
                        }
                        .buttonStyle(.plain)

                        if game.id != search.results.last?.id {
                            Divider().padding(.leading, 74)
                        }
                    }
                }
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.horizontal, 16)
            }
            // Fills whatever space is left below the search field; scrolls
            // internally once the results outgrow the screen.
            .frame(maxHeight: .infinity)
            .padding(.top, 8)
        } else {
            Spacer(minLength: 0)
        }
    }

    private func statusRow(_ text: String) -> some View {
        HStack {
            if search.isSearching {
                ProgressView()
            }
            Text(text)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    // MARK: Selected game details

    private func selectedGameDetails(_ game: IGDBGame) -> some View {
        Form {
            Section {
                HStack(spacing: 12) {
                    CoverThumbnail(url: game.cover?.url)

                    Text(game.name)
                        .font(.headline)
                        .lineLimit(2)

                    Spacer()

                    Button(String(localized: "addGame.search.change")) {
                        clearSelection()
                    }
                    .font(.subheadline)
                }
            }

            if let platforms = game.platforms, !platforms.isEmpty {
                Section {
                    Picker(String(localized: "addGame.field.platform"), selection: $selectedPlatform) {
                        ForEach(platforms, id: \.id) { platform in
                            Text(platform.name).tag(platform.name)
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
    }

    // MARK: Actions

    private func select(_ game: IGDBGame) {
        selectedGame = game
        selectedPlatform = game.platforms?.first?.name ?? ""
        searchFieldFocused = false
    }

    private func clearSelection() {
        selectedGame = nil
        selectedPlatform = ""
        search.reset()
        searchFieldFocused = true
    }

    private func addGame() {
        guard let selectedGame else { return }
        // Progress tracking isn't wired up yet — every new game starts at 0
        // regardless of status until that's designed separately.
        let game = Game(
            title: selectedGame.name,
            platform: selectedPlatform,
            status: status,
            progress: 0,
            activity: String(localized: "activity.justAdded"),
            coverURL: selectedGame.cover?.url,
            // IGDB's own platform list can't be assumed unique — `EditGameView`
            // relies on `id: \.self` for these, so duplicates would confuse
            // SwiftUI's diffing. De-duplicate once here rather than there.
            availablePlatforms: (selectedGame.platforms?.map(\.name) ?? []).uniqued()
        )
        modelContext.insert(game)
        // Autosave is timing-dependent (ties to scene-phase transitions) —
        // save explicitly so the game survives an immediate force-quit.
        do {
            try modelContext.save()
        } catch {
            assertionFailure("Failed to save new game: \(error)")
        }
        dismiss()
    }
}

private extension Array where Element: Hashable {
    /// Order-preserving de-duplication.
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}

// MARK: - Search result row

private struct SearchResultRow: View {
    let game: IGDBGame

    var body: some View {
        HStack(spacing: 12) {
            CoverThumbnail(url: game.cover?.url)

            VStack(alignment: .leading, spacing: 2) {
                Text(game.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                if let platformNames {
                    Text(platformNames)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }

    private var platformNames: String? {
        guard let platforms = game.platforms, !platforms.isEmpty else { return nil }
        return platforms.map(\.name).joined(separator: ", ")
    }
}

// MARK: - Cover thumbnail

/// Shared by the search results row and `EditGameView`'s header.
struct CoverThumbnail: View {
    let url: URL?

    var body: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(Color(.tertiarySystemGroupedBackground))
            .frame(width: 40, height: 54)
            .overlay {
                if let url {
                    AsyncImage(url: url) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "gamecontroller.fill")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Image(systemName: "gamecontroller.fill")
                        .foregroundStyle(.secondary)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            // Decorative — the adjacent game title already carries the label.
            .accessibilityHidden(true)
    }
}

#Preview {
    AddGameView()
        .modelContainer(for: Game.self, inMemory: true)
}
