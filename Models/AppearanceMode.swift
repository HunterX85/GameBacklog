//
//  AppearanceMode.swift
//  GameBacklog
//
//  Created by Serhii Pershuta on 12.08.2026.
//

import SwiftUI

/// User-selected app theme, persisted via `@AppStorage(AppearanceMode.storageKey)`.
///
/// `.system` maps to a `nil` `ColorScheme` so SwiftUI keeps following the
/// device setting rather than pinning to whatever it resolved to at read time.
enum AppearanceMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    /// Shared `@AppStorage` key — same string used wherever this mode is read or written.
    static let storageKey = "settings.appearanceMode"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: String(localized: "settings.appearance.system")
        case .light:  String(localized: "settings.appearance.light")
        case .dark:   String(localized: "settings.appearance.dark")
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light:  .light
        case .dark:   .dark
        }
    }
}
