//
//  ContentView.swift
//  GameBacklog
//
//  Created by Serhii Pershuta on 02.05.2026.
//

import SwiftUI

/// Tabs hosted by the custom floating tab bar.
enum AppTab: String, CaseIterable, Identifiable {
    case games
    case profile
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .games:    String(localized: "tab.games")
        case .profile:  String(localized: "tab.profile")
        case .settings: String(localized: "tab.settings")
        }
    }

    var symbol: String {
        switch self {
        case .games:    "gamecontroller.fill"
        case .profile:  "person.fill"
        case .settings: "gearshape.fill"
        }
    }
}

struct ContentView: View {
    @State private var selectedTab: AppTab = .games
    @AppStorage(AppearanceMode.storageKey) private var appearanceMode: AppearanceMode = .system
    // Shared across tabs so Profile's locally-stored fields can be
    // namespaced by the signed-in account — see ProfileViewModel.
    @StateObject private var authViewModel = AuthViewModel()

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            FloatingTabBar(selection: $selectedTab)
                .padding(.horizontal, 40)
                .padding(.bottom, 8)
        }
        .environmentObject(authViewModel)
        .preferredColorScheme(appearanceMode.colorScheme)
        .onOpenURL { url in
            Task { await authViewModel.handleAuthCallback(url: url) }
        }
    }

    // All three tabs stay mounted for ContentView's lifetime instead of a
    // `switch` that rebuilds whichever one isn't selected — a `switch` here
    // would tear down and recreate each screen's `@StateObject` on every
    // tab change, silently discarding in-progress edits (e.g. an unsaved
    // Profile field).
    @ViewBuilder
    private var content: some View {
        tab(.games) { GamesScreenView() }
        tab(.profile) { NavigationStack { ProfileScreenView() } }
        tab(.settings) { NavigationStack { SettingsScreenView() } }
    }

    @ViewBuilder
    private func tab<Content: View>(_ tab: AppTab, @ViewBuilder content: () -> Content) -> some View {
        content()
            .opacity(selectedTab == tab ? 1 : 0)
            .allowsHitTesting(selectedTab == tab)
            .accessibilityHidden(selectedTab != tab)
    }
}

// MARK: - Floating tab bar

/// Pill-shaped tab bar floating above the content, matching the mockup.
struct FloatingTabBar: View {
    @Binding var selection: AppTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { tab in
                Button {
                    withAnimation(.snappy(duration: 0.25)) { selection = tab }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.symbol)
                            .font(.system(size: 20, weight: .semibold))
                        Text(tab.title)
                            .font(.caption2.weight(.medium))
                    }
                    .foregroundStyle(selection == tab ? Color.accentColor : Color.secondary)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(
            Capsule()
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 6)
        )
    }
}

#Preview {
    ContentView()
}
