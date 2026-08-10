//
//  IGDBService.swift
//  GameBacklog
//
//  Created by Serhii Pershuta on 10.08.2026.
//

import Foundation

/// Thin client for the IGDB `/v4/games` search endpoint.
final class IGDBService {
    enum ServiceError: Error {
        case invalidResponse
    }

    /// Shared instance so the underlying `IGDBAuthService`'s cached Twitch
    /// token survives across `AddGameView` presentations instead of
    /// re-authenticating every time the search sheet is opened.
    static let shared: IGDBService? = try? IGDBService()

    private let clientID: String
    private let auth: IGDBAuthService
    private let session: URLSession

    init(session: URLSession = .shared) throws {
        guard let clientID = Bundle.main.igdbClientID, !clientID.isEmpty else {
            throw IGDBAuthService.AuthError.missingCredentials
        }
        self.clientID = clientID
        self.session = session
        self.auth = try IGDBAuthService(session: session)
    }

    /// Searches IGDB by title. Queries are sent in Apicalypse, IGDB's query language.
    func searchGames(query: String, limit: Int = 20) async throws -> [IGDBGame] {
        let token = try await auth.accessToken()

        var request = URLRequest(url: URL(string: "https://api.igdb.com/v4/games")!)
        request.httpMethod = "POST"
        request.setValue(clientID, forHTTPHeaderField: "Client-ID")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("text/plain", forHTTPHeaderField: "Content-Type")

        // Escape backslashes before quotes so neither can break out of the
        // Apicalypse string literal (order matters: quoting first would
        // re-escape the backslash we just inserted).
        let escapedQuery = query
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        let apicalypseQuery = """
        search "\(escapedQuery)";
        fields name, platforms.name, cover.image_id;
        limit \(limit);
        """
        request.httpBody = apicalypseQuery.data(using: .utf8)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw ServiceError.invalidResponse
        }

        return try JSONDecoder().decode([IGDBGame].self, from: data)
    }
}
