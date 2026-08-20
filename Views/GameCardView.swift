//
//  GameCardView.swift
//  GameBacklog
//
//  Created by Serhii Pershuta on 11.06.2026.
//

import SwiftUI

/// A single backlog entry rendered as an elevated card, matching the
/// Games screen mockup. Composed of small, independently-previewable pieces.
struct GameCardView: View {
    let game: Game

    @EnvironmentObject private var gamesViewModel: GamesViewModel
    @State private var showingEdit = false
    @State private var showingProgress = false

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            GameCover(tint: game.status.tint, coverURL: game.coverURL)

            VStack(alignment: .leading, spacing: 8) {
                header
                subtitleRow

                if game.status.showsProgress {
                    GameProgressBar(progress: game.progress, tint: game.status.tint)
                }

                activityRow
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
        .sheet(isPresented: $showingEdit) {
            EditGameView(game: game)
        }
        .sheet(isPresented: $showingProgress) {
            UpdateProgressView(game: game)
        }
    }

    // MARK: Subviews

    private var header: some View {
        HStack(alignment: .top) {
            Text(game.title)
                .font(.headline)
                .foregroundStyle(.primary)
                .lineLimit(2)

            Spacer(minLength: 8)

            Menu {
                Button {
                    showingEdit = true
                } label: {
                    Label(String(localized: "gameCard.action.update"), systemImage: "pencil")
                }
                if game.status.showsProgress {
                    Button {
                        showingProgress = true
                    } label: {
                        Label(String(localized: "gameCard.action.progress"), systemImage: "gauge.with.dots.needle.50percent")
                    }
                }
                Button(role: .destructive) {
                    Task { await gamesViewModel.delete(id: game.id) }
                } label: {
                    Label(String(localized: "gameCard.action.delete"), systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 24, alignment: .top)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel(Text("Options"))
        }
    }

    private var subtitleRow: some View {
        HStack {
            Text(game.platform)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer(minLength: 8)
            StatusBadge(status: game.status)
        }
    }

    private var activityRow: some View {
        Label {
            Text(game.activity)
                .font(.footnote)
                .foregroundStyle(.secondary)
        } icon: {
            Image(systemName: game.status.activitySymbol)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 2)
    }

}

// MARK: - Cover art

/// IGDB box art when available, otherwise a tinted gradient tile with a
/// controller glyph — the same stand-in used before games carried real covers.
private struct GameCover: View {
    let tint: Color
    let coverURL: URL?

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [tint.opacity(0.85), tint.opacity(0.45)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            if let coverURL {
                AsyncImage(url: coverURL) { phase in
                    if case .success(let image) = phase {
                        image.resizable().aspectRatio(contentMode: .fill)
                    }
                }
            } else {
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
            }
        }
        .frame(width: 72, height: 96)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - Status badge

/// Pill-shaped status indicator tinted to match the game's status.
struct StatusBadge: View {
    let status: GameStatus

    var body: some View {
        Text(status.title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(status.tint)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(status.tint.opacity(0.15), in: Capsule())
    }
}

// MARK: - Progress bar

/// Rounded, animatable completion bar with a trailing percentage label.
struct GameProgressBar: View {
    let progress: Double
    let tint: Color

    private var clamped: Double { min(max(progress, 0), 1) }

    var body: some View {
        HStack(spacing: 10) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemGray5))
                    Capsule()
                        .fill(tint)
                        .frame(width: geo.size.width * clamped)
                }
            }
            .frame(height: 6)

            Text(clamped, format: .percent.precision(.fractionLength(0)))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .monospacedDigit()
                .frame(width: 44, alignment: .trailing)
        }
    }
}

#Preview {
    let samples = Game.samples

    return ScrollView {
        VStack(spacing: 16) {
            ForEach(samples) { game in
                GameCardView(game: game)
            }
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
    .environmentObject(GamesViewModel(previewGames: samples))
}
