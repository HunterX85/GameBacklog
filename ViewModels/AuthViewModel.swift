//
//  AuthViewModel.swift
//  GameBacklog
//
//  Created by Serhii Pershuta on 12.08.2026.
//

import Combine
import Foundation
import Supabase

/// Drives the optional sign in / sign up section on the Settings screen.
///
/// Signing in is never required to use the rest of the app — this just
/// tracks Supabase's own session state so the UI can reflect it.
@MainActor
final class AuthViewModel: ObservableObject {
    enum Mode: Hashable {
        case signIn
        case signUp
    }

    @Published var mode: Mode = .signIn {
        didSet {
            errorMessage = nil
            infoMessage = nil
        }
    }
    @Published var email = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var infoMessage: String?
    @Published private(set) var currentUserEmail: String?

    var isSignedIn: Bool { currentUserEmail != nil }

    /// Whitespace-only email should not enable the button — `submit()` trims
    /// before validating, so the button's enabled state needs to agree.
    var canSubmit: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !password.isEmpty
    }

    private let client: SupabaseClient?
    private var authStateTask: Task<Void, Never>?

    init(client: SupabaseClient? = SupabaseClientProvider.shared) {
        self.client = client
        guard let client else { return }
        authStateTask = Task { [weak self] in
            for await (_, session) in client.auth.authStateChanges {
                self?.currentUserEmail = session?.user.email
            }
        }
    }

    deinit {
        authStateTask?.cancel()
    }

    func submit() async {
        guard let client else {
            errorMessage = String(localized: "settings.account.notConfigured")
            return
        }
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty, !password.isEmpty else { return }

        isLoading = true
        errorMessage = nil
        infoMessage = nil
        defer { isLoading = false }

        do {
            switch mode {
            case .signIn:
                try await client.auth.signIn(email: trimmedEmail, password: password)
            case .signUp:
                let response = try await client.auth.signUp(email: trimmedEmail, password: password)
                if response.session == nil {
                    infoMessage = String(localized: "settings.account.confirmEmail")
                }
            }
            password = ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signOut() async {
        guard let client else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            try await client.auth.signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
