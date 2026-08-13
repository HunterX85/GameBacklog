//
//  SettingsViewModel.swift
//  GameBacklog
//
//  Created by Serhii Pershuta on 12.08.2026.
//

import Combine
import Foundation

/// Drives the Data Management section of the Settings screen: clearing the
/// cover-art cache and exporting/importing the backlog as JSON.
@MainActor
final class SettingsViewModel: ObservableObject {
    @Published private(set) var isExporting = false
    @Published private(set) var isImporting = false
    @Published private(set) var cacheByteCount = 0
    /// Set after a successful import so the view can show "N games imported."
    /// `nil` again once a new export/import cycle starts.
    @Published private(set) var lastImportedCount: Int?
    @Published private(set) var errorMessage: String?

    private let repository: GamesRepository
    private let cache: URLCache
    private let fileManager: FileManager

    init(
        repository: GamesRepository = .shared,
        cache: URLCache = .shared,
        fileManager: FileManager = .default
    ) {
        self.repository = repository
        self.cache = cache
        self.fileManager = fileManager
        refreshCacheUsage()
    }

    var formattedCacheSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(cacheByteCount), countStyle: .file)
    }

    func refreshCacheUsage() {
        cacheByteCount = cache.currentDiskUsage
    }

    /// Cover art is fetched via plain `AsyncImage`/`URLSession.shared`, so it
    /// lives in the shared `URLCache` — there's no bespoke disk cache to clean.
    ///
    /// `removeAllCachedResponses()` removes entries on a background queue and
    /// returns before that finishes, so re-reading `currentDiskUsage` right
    /// after it — as `refreshCacheUsage()` does — can still report the old
    /// size. Reporting zero directly is accurate here since a full clear was
    /// just requested.
    func clearCoverCache() {
        cache.removeAllCachedResponses()
        cacheByteCount = 0
    }

    /// Writes the current backlog to a JSON file under `NSTemporaryDirectory()`
    /// for the caller to hand to a share sheet. The OS reclaims temp files on
    /// its own schedule, so nothing here deletes it afterward.
    func exportBacklog() async -> URL? {
        isExporting = true
        errorMessage = nil
        lastImportedCount = nil
        defer { isExporting = false }

        do {
            let games = try await repository.fetchAll()
            let export = BacklogExport(games: games)

            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(export)

            let url = fileManager.temporaryDirectory.appendingPathComponent(exportFilename())
            try data.write(to: url, options: .atomic)
            return url
        } catch GamesRepository.RepositoryError.notConfigured {
            errorMessage = String(localized: "settings.dataManagement.notConfigured")
            return nil
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    /// Inserts every game from the file as a new backlog entry. Existing
    /// games are untouched — this merges rather than replaces.
    ///
    /// If a mid-loop insert fails, the games before it stay committed; there's
    /// no rollback. Good enough for an MVP import path — a partial import is
    /// easy to spot (fewer games than expected in the success count) and
    /// simply re-running the import is safe, since every run only adds rows.
    @discardableResult
    func importBacklog(from url: URL) async -> Bool {
        isImporting = true
        errorMessage = nil
        lastImportedCount = nil
        defer { isImporting = false }

        let isSecurityScoped = url.startAccessingSecurityScopedResource()
        defer { if isSecurityScoped { url.stopAccessingSecurityScopedResource() } }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let export = try decoder.decode(BacklogExport.self, from: data)

            // A file from a newer app version could carry a schema this build
            // doesn't understand yet — decoding would silently succeed on the
            // fields it recognizes rather than failing loudly, so the version
            // needs its own explicit check.
            guard export.version <= BacklogExport.currentVersion else {
                errorMessage = String(localized: "settings.dataManagement.import.invalidFile")
                return false
            }

            for entry in export.games {
                _ = try await repository.insert(entry.draft)
            }
            lastImportedCount = export.games.count
            return true
        } catch is DecodingError {
            errorMessage = String(localized: "settings.dataManagement.import.invalidFile")
            return false
        } catch GamesRepository.RepositoryError.notConfigured {
            errorMessage = String(localized: "settings.dataManagement.notConfigured")
            return false
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    /// Surfaces a failure from the system file picker itself (e.g. `.fileImporter`
    /// couldn't resolve the picked URL) — distinct from a failure while reading
    /// or decoding a file that was successfully picked.
    func reportPickerFailure(_ error: Error) {
        errorMessage = error.localizedDescription
    }

    private func exportFilename() -> String {
        let formatter = DateFormatter()
        // Without pinning these, a device set to a non-Gregorian calendar
        // (e.g. Persian, Buddhist) would format "yyyy" against that calendar's
        // era year, producing a filename with a wildly different date.
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return "GameBacklog-\(formatter.string(from: .now)).json"
    }
}
