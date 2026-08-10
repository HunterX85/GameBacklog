//
//  GamesScreenView.swift
//  GameBacklog
//
//  Created by Serhii Pershuta on 11.06.2026.
//

import SwiftUI

/// The Games tab: a scrollable backlog with a custom large-title header and a
/// segmented filter control. Built without `List`/`navigationTitle` so the
/// layout can match the mockup pixel-for-pixel.
struct GamesScreenView: View {
    @ObservedObject var viewModel: GameListViewModel
    @State private var showingAddGame = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header
                GameFilterBar(selection: $viewModel.filter)

                LazyVStack(spacing: 16) {
                    ForEach(viewModel.filteredGames) { game in
                        GameCardView(game: game)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            // Leave room for the floating tab bar.
            .padding(.bottom, 120)
        }
        .background(Color(.systemGroupedBackground))
        .scrollIndicators(.hidden)
        .sheet(isPresented: $showingAddGame) {
            AddGameView(viewModel: viewModel)
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "app.title"))
                    .font(.largeTitle.bold())

                Text(subtitle)
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

    private var subtitle: String {
        String(
            format: String(localized: "games.subtitle"),
            viewModel.totalCount,
            viewModel.completedCount
        )
    }
}

// MARK: - Filter bar

/// Segmented pill control with a sliding white selection indicator driven by
/// `matchedGeometryEffect` for a smooth, native-feeling transition.
struct GameFilterBar: View {
    @Binding var selection: GameFilter
    @Namespace private var namespace

    var body: some View {
        HStack(spacing: 0) {
            ForEach(GameFilter.allCases) { filter in
                let isSelected = filter == selection

                Text(filter.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isSelected ? .primary : .secondary)
                    .frame(maxWidth: .infinity)
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
                    .onTapGesture {
                        withAnimation(.snappy(duration: 0.28)) {
                            selection = filter
                        }
                    }
            }
        }
        .padding(4)
        .background(Color(.tertiarySystemGroupedBackground), in: Capsule())
    }
}

#Preview {
    GamesScreenView(viewModel: GameListViewModel())
}
