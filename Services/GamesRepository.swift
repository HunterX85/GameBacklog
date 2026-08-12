//
//  GamesRepository.swift
//  GameBacklog
//
//  Created by Serhii Pershuta on 12.08.2026.
//

import Foundation
import Supabase

/// CRUD access to the `games` table.
///
/// Every call first makes sure there's a session — signing in anonymously if
/// there isn't one — since RLS requires `auth.uid()` even for a user who
/// never taps Sign In. Anonymous games aren't carried over if that user later
/// signs up; that's a deliberate MVP simplification, not an oversight.
final class GamesRepository {
    enum RepositoryError: Error {
        case notConfigured
    }

    static let shared = GamesRepository()

    private let client: SupabaseClient?

    init(client: SupabaseClient? = SupabaseClientProvider.shared) {
        self.client = client
    }

    func fetchAll() async throws -> [Game] {
        let client = try requireClient()
        try await ensureSession(client)
        return try await client
            .from("games")
            .select()
            .order("date_added", ascending: true)
            .execute()
            .value
    }

    func insert(_ draft: Game.Draft) async throws -> Game {
        let client = try requireClient()
        try await ensureSession(client)
        return try await withOrphanedSessionRecovery(client) {
            try await client
                .from("games")
                .insert(draft)
                .select()
                .single()
                .execute()
                .value
        }
    }

    func update(id: UUID, with update: Game.Update) async throws -> Game {
        let client = try requireClient()
        try await ensureSession(client)
        return try await withOrphanedSessionRecovery(client) {
            try await client
                .from("games")
                .update(update)
                .eq("id", value: id)
                .select()
                .single()
                .execute()
                .value
        }
    }

    func delete(id: UUID) async throws {
        let client = try requireClient()
        try await ensureSession(client)
        try await withOrphanedSessionRecovery(client) {
            try await client
                .from("games")
                .delete()
                .eq("id", value: id)
                .execute()
        }
    }

    private func requireClient() throws -> SupabaseClient {
        guard let client else { throw RepositoryError.notConfigured }
        return client
    }

    /// Cheap on the common path — `auth.session` just reads the cached/refreshed
    /// session and only throws when there's genuinely none (first launch, or
    /// right after a manual sign-out).
    private func ensureSession(_ client: SupabaseClient) async throws {
        if (try? await client.auth.session) != nil { return }
        _ = try await client.auth.signInAnonymously()
    }

    /// A locally cached session can outlive the `auth.users` row it points to
    /// — e.g. an anonymous account removed server-side while the device's
    /// refresh token is still "valid". That surfaces as a foreign-key
    /// violation on `user_id`, not an auth error, so `ensureSession` alone
    /// never catches it. Recover once by forcing a brand-new session.
    private func withOrphanedSessionRecovery<T>(
        _ client: SupabaseClient,
        _ operation: () async throws -> T
    ) async throws -> T {
        do {
            return try await operation()
        } catch let error as PostgrestError where error.code == "23503" {
            try? await client.auth.signOut()
            _ = try await client.auth.signInAnonymously()
            return try await operation()
        }
    }
}
