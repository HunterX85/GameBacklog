//
//  GamesScreenView.swift
//  GameBacklog
//
//  Created by Serhii Pershuta on 11.06.2026.
//

import SwiftUI

/// Top-level filter shown as a segmented control on the Games screen.
enum GameFilter: String, CaseIterable, Identifiable {
    case all
    case backlog
    case playing
    case completed
    case dropped

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:       String(localized: "filter.all")
        case .backlog:   String(localized: "filter.backlog")
        case .playing:   String(localized: "filter.playing")
        case .completed: String(localized: "filter.completed")
        case .dropped:   String(localized: "filter.dropped")
        }
    }

    /// Status this filter maps to, or `nil` for the catch-all `.all` case.
    var matchingStatus: GameStatus? {
        switch self {
        case .all:       nil
        case .backlog:   .backlog
        case .playing:   .playing
        case .completed: .completed
        case .dropped:   .dropped
        }
    }
}

/// The Games tab: a scrollable backlog with a custom large-title header and a
/// segmented filter control. Built without `List`/`navigationTitle` so the
/// layout can match the mockup pixel-for-pixel.
struct GamesScreenView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @StateObject private var viewModel: GamesViewModel
    @State private var filter: GameFilter = .all
    @State private var showingAddGame = false

    init(viewModel: GamesViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    init() {
        self.init(viewModel: GamesViewModel())
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header
                GameFilterBar(selection: $filter)

                if viewModel.isLoading && !viewModel.hasLoadedOnce {
                    ProgressView()
                        .padding(.vertical, 60)
                } else if filteredGames.isEmpty {
                    EmptyGamesView(hasAnyGames: !viewModel.games.isEmpty)
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredGames) { game in
                            GameCardView(game: game)
                        }
                    }
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .background(Color(.systemGroupedBackground))
        .scrollIndicators(.hidden)
        // Reserves room for the floating tab bar overlay, which sits outside
        // the normal safe-area system — see `FloatingTabBar.reservedHeight`.
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: FloatingTabBar.reservedHeight)
        }
        .refreshable { await viewModel.load() }
        .task { await viewModel.loadIfNeeded() }
        // Games now stays mounted for the app's lifetime instead of being
        // torn down on every tab switch (see ContentView), so the sign-in
        // teardown/rebuild this used to piggyback on for a fresh fetch no
        // longer happens on its own — force a reload whenever the signed-in
        // account actually changes. `loadIfNeeded()` above already covers
        // the very first load, so this only reacts to later changes.
        .onChange(of: authViewModel.currentUserID) { _, _ in
            Task { await viewModel.load() }
        }
        .sheet(isPresented: $showingAddGame) {
            AddGameView()
        }
        .environmentObject(viewModel)
    }

    // MARK: Derived state

    /// Games matching the currently selected filter, preserving fetch order.
    private var filteredGames: [Game] {
        guard let status = filter.matchingStatus else { return viewModel.games }
        return viewModel.games.filter { $0.status == status }
    }

    private var completedCount: Int {
        viewModel.games.lazy.filter { $0.status == .completed }.count
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "app.title"))
                    .font(.largeTitle.bold())

                subtitle
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                showingAddGame = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 48, height: 48)
                    .background(Color(.secondarySystemGroupedBackground), in: Circle())
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(String(localized: "addGame.title")))
        }
    }

    /// `^[...](inflect: true)` triggers Foundation's automatic grammar
    /// agreement so "1 game" / "2 games" resolves correctly instead of the
    /// plain `%lld games` this replaced, which was always plural.
    private var subtitle: Text {
        Text("^[\(viewModel.games.count) game](inflect: true) • \(completedCount) completed")
    }
}

// MARK: - Filter bar

/// Horizontally scrolling pill control with a sliding white selection
/// indicator driven by `matchedGeometryEffect` for a smooth, native-feeling
/// transition. Chips size to their own text instead of splitting the width
/// equally, so adding more filters (e.g. `.dropped`) doesn't squeeze existing
/// ones — it just extends how far the row scrolls.
struct GameFilterBar: View {
    @Binding var selection: GameFilter
    @Namespace private var namespace

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(GameFilter.allCases) { filter in
                    let isSelected = filter == selection

                    Button {
                        withAnimation(.snappy(duration: 0.28)) {
                            selection = filter
                        }
                    } label: {
                        Text(filter.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(isSelected ? .primary : .secondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background {
                                if isSelected {
                                    Capsule()
                                        .fill(Color(.secondarySystemGroupedBackground))
                                        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 2)
                                        .matchedGeometryEffect(id: "selectedFilter", in: namespace)
                                }
                            }
                            .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    // VoiceOver has no other way to tell which filter is active.
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
            .padding(4)
            .background(Color(.tertiarySystemGroupedBackground), in: Capsule())
        }
    }
}

// MARK: - Empty state

/// Shown when the backlog has no games yet, or when the current filter has
/// no matches — the two cases get different copy so it's clear which one it is.
private struct EmptyGamesView: View {
    let hasAnyGames: Bool

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: hasAnyGames ? "line.3.horizontal.decrease.circle" : "gamecontroller")
                .font(.system(size: 40, weight: .medium))
                .foregroundStyle(.secondary)

            Text(hasAnyGames ? String(localized: "games.empty.filtered.title") : String(localized: "games.empty.title"))
                .font(.headline)

            Text(hasAnyGames ? String(localized: "games.empty.filtered.subtitle") : String(localized: "games.empty.subtitle"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .padding(.horizontal, 32)
    }
}

#Preview {
    GamesScreenView(viewModel: GamesViewModel(previewGames: []))
        .environmentObject(AuthViewModel())
}

#Preview("With games") {
    GamesScreenView(viewModel: GamesViewModel(previewGames: Game.samples))
        .environmentObject(AuthViewModel())
}
