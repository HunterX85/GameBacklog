//
//  SupabaseClientProvider.swift
//  GameBacklog
//
//  Created by Serhii Pershuta on 12.08.2026.
//

import Foundation
import Supabase

enum SupabaseConfigError: Error {
    case missingConfiguration
}

/// Lazily builds the shared `SupabaseClient` from `Config/Secrets.xcconfig`.
enum SupabaseClientProvider {
    /// `nil` when Secrets.xcconfig hasn't been filled in — callers should
    /// degrade gracefully rather than crash, same convention as `IGDBService.shared`.
    static let shared: SupabaseClient? = try? makeClient()

    private static func makeClient() throws -> SupabaseClient {
        guard
            let host = Bundle.main.supabaseURLHost, !host.isEmpty,
            let key = Bundle.main.supabasePublishableKey, !key.isEmpty,
            let url = URL(string: "https://\(host)")
        else {
            throw SupabaseConfigError.missingConfiguration
        }
        return SupabaseClient(supabaseURL: url, supabaseKey: key)
    }
}

extension Bundle {
    var supabaseURLHost: String? { object(forInfoDictionaryKey: "SupabaseURLHost") as? String }
    var supabasePublishableKey: String? { object(forInfoDictionaryKey: "SupabasePublishableKey") as? String }
}
