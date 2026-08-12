//
//  SettingsScreenView.swift
//  GameBacklog
//
//  Created by Serhii Pershuta on 12.08.2026.
//

import SwiftUI

struct SettingsScreenView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @FocusState private var focusedField: Field?

    private enum Field {
        case email
        case password
    }

    var body: some View {
        Form {
            Section(String(localized: "settings.section.account")) {
                if authViewModel.isSignedIn {
                    signedInContent
                } else {
                    signedOutContent
                }
            }
        }
        .formStyle(.grouped)
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(String(localized: "tab.settings"))
    }

    @ViewBuilder
    private var signedInContent: some View {
        LabeledContent(String(localized: "settings.account.signedInAs"), value: authViewModel.currentUserEmail ?? "")

        Button(role: .destructive) {
            Task { await authViewModel.signOut() }
        } label: {
            HStack {
                Text(String(localized: "settings.account.signOut"))
                if authViewModel.isLoading {
                    Spacer()
                    ProgressView()
                }
            }
        }
        .disabled(authViewModel.isLoading)
    }

    @ViewBuilder
    private var signedOutContent: some View {
        Picker(String(localized: "settings.account.mode"), selection: $authViewModel.mode) {
            Text(String(localized: "settings.account.signIn")).tag(AuthViewModel.Mode.signIn)
            Text(String(localized: "settings.account.signUp")).tag(AuthViewModel.Mode.signUp)
        }
        .pickerStyle(.segmented)
        .listRowSeparator(.hidden)
        .disabled(authViewModel.isLoading)

        TextField(String(localized: "settings.account.email"), text: $authViewModel.email)
            .textContentType(.emailAddress)
            .textInputAutocapitalization(.never)
            .keyboardType(.emailAddress)
            .autocorrectionDisabled()
            .submitLabel(.next)
            .focused($focusedField, equals: .email)
            .onSubmit { focusedField = .password }
            .accessibilityIdentifier("accountEmail")

        SecureField(String(localized: "settings.account.password"), text: $authViewModel.password)
            .textContentType(authViewModel.mode == .signIn ? .password : .newPassword)
            .submitLabel(.go)
            .focused($focusedField, equals: .password)
            .onSubmit {
                guard authViewModel.canSubmit else { return }
                Task {
                    await authViewModel.submit()
                    focusedField = nil
                }
            }
            .accessibilityIdentifier("accountPassword")

        if let errorMessage = authViewModel.errorMessage {
            Text(errorMessage)
                .font(.footnote)
                .foregroundStyle(.red)
        }

        if let infoMessage = authViewModel.infoMessage {
            Text(infoMessage)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }

        Button {
            Task {
                await authViewModel.submit()
                focusedField = nil
            }
        } label: {
            HStack {
                Spacer()
                if authViewModel.isLoading {
                    ProgressView()
                } else {
                    Text(authViewModel.mode == .signIn
                         ? String(localized: "settings.account.signIn")
                         : String(localized: "settings.account.signUp"))
                }
                Spacer()
            }
        }
        .disabled(authViewModel.isLoading || !authViewModel.canSubmit)
        .accessibilityIdentifier("accountSubmit")
    }
}

#Preview {
    NavigationStack {
        SettingsScreenView()
    }
}
