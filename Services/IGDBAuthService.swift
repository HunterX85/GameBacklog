//
//  IGDBAuthService.swift
//  GameBacklog
//
//  Created by Serhii Pershuta on 10.08.2026.
//

import Foundation
import Supabase

/// Obtains and caches the IGDB access token + client ID via the `igdb-token`
/// Supabase Edge Function, which holds the actual Twitch client secret
/// server-side — the app never sees it.
///
/// Tokens live ~60 days, so an in-memory cache is enough; there's no need to
/// persist across launches.
actor IGDBAuthService {
    enum AuthError: Error {
        case notConfigured
    }

    struct Credentials {
        let accessToken: String
        let clientID: String
    }

    private struct TokenResponse: Decodable {
        let accessToken: String
        let clientID: String
        let expiresAt: Int

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case clientID = "client_id"
            case expiresAt = "expires_at"
        }
    }

    private let client: SupabaseClient
    private var cached: TokenResponse?

    init(client: SupabaseClient? = SupabaseClientProvider.shared) throws {
        guard let client else { throw AuthError.notConfigured }
        self.client = client
    }

    /// Returns cached credentials if the token is still valid, otherwise fetches fresh ones.
    func credentials() async throws -> Credentials {
        if let cached, TimeInterval(cached.expiresAt) > Date().timeIntervalSince1970 {
            return Credentials(accessToken: cached.accessToken, clientID: cached.clientID)
        }
        let response: TokenResponse = try await client.functions.invoke("igdb-token")
        cached = response
        return Credentials(accessToken: response.accessToken, clientID: response.clientID)
    }
}
