//
//  IGDBAuthService.swift
//  GameBacklog
//
//  Created by Serhii Pershuta on 10.08.2026.
//

import Foundation

/// Obtains and caches the Twitch app-access token IGDB requires on every request.
///
/// IGDB has no auth endpoint of its own — tokens come from Twitch's Client
/// Credentials Grant (`id.twitch.tv/oauth2/token`). Tokens live ~60 days, so
/// an in-memory cache is enough; there's no need to persist across launches.
actor IGDBAuthService {
    enum AuthError: Error {
        case missingCredentials
        case invalidResponse
    }

    private struct TokenResponse: Decodable {
        let accessToken: String
        let expiresIn: Int

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case expiresIn = "expires_in"
        }
    }

    private let clientID: String
    private let clientSecret: String
    private let session: URLSession

    private var cachedToken: String?
    private var expiresAt: Date?

    init(session: URLSession = .shared) throws {
        guard
            let clientID = Bundle.main.igdbClientID,
            let clientSecret = Bundle.main.igdbClientSecret,
            !clientID.isEmpty, !clientSecret.isEmpty
        else {
            throw AuthError.missingCredentials
        }
        self.clientID = clientID
        self.clientSecret = clientSecret
        self.session = session
    }

    /// Returns a cached token if still valid, otherwise requests a fresh one.
    func accessToken() async throws -> String {
        if let cachedToken, let expiresAt, expiresAt > Date() {
            return cachedToken
        }
        return try await fetchToken()
    }

    private func fetchToken() async throws -> String {
        var request = URLRequest(url: URL(string: "https://id.twitch.tv/oauth2/token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        var body = URLComponents()
        body.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "client_secret", value: clientSecret),
            URLQueryItem(name: "grant_type", value: "client_credentials")
        ]
        request.httpBody = body.percentEncodedQuery?.data(using: .utf8)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw AuthError.invalidResponse
        }

        let decoded = try JSONDecoder().decode(TokenResponse.self, from: data)
        cachedToken = decoded.accessToken
        // Refresh a minute early so an in-flight request never races expiry.
        expiresAt = Date().addingTimeInterval(TimeInterval(decoded.expiresIn) - 60)
        return decoded.accessToken
    }
}

extension Bundle {
    var igdbClientID: String? { object(forInfoDictionaryKey: "IGDBClientID") as? String }
    var igdbClientSecret: String? { object(forInfoDictionaryKey: "IGDBClientSecret") as? String }
}
