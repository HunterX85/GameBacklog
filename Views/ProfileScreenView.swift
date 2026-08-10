//
//  ProfileScreenView.swift
//  GameBacklog
//
//  Created by Serhii Pershuta on 10.06.2026.
//

import SwiftUI

struct ProfileScreenView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showSnackbar = false

    var body: some View {
        Form {
            Section(String(localized: "profile.section.personalInfo")) {
                TextField(String(localized: "profile.field.firstName"), text: $viewModel.firstName)
                    .accessibilityIdentifier("firstName")
                TextField(String(localized: "profile.field.lastName"), text: $viewModel.lastName)
                    .accessibilityIdentifier("lastName")
                TextField(String(localized: "profile.field.nickname"), text: $viewModel.nickname)
                    .accessibilityIdentifier("nickname")
            }

            Section(String(localized: "profile.section.contacts")) {
                TextField(String(localized: "profile.field.email"), text: $viewModel.email)
                    .keyboardType(.emailAddress)
                    .accessibilityIdentifier("email")
            }
        }
        .onTapGesture {
            hideKeyboard()
        }
        .overlay(alignment: .bottom) {
            if showSnackbar {
                Text(String(localized: "profile.snackbar.saved"))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color(.label))
                    .foregroundStyle(Color(.systemBackground))
                    .clipShape(Capsule())
                    .padding(.bottom, 16)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showSnackbar)
        .navigationTitle(String(localized: "profile.title"))
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(String(localized: "profile.button.save")) {
                    viewModel.save()
                    hideKeyboard()
                    showSnackbar = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showSnackbar = false
                    }
                }
            }
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    NavigationStack {
        ProfileScreenView()
    }
}
