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
            Section("Personal Info") {
                TextField("First Name", text: $viewModel.firstName).accessibilityIdentifier("firstName")
                TextField("Last Name", text: $viewModel.lastName).accessibilityIdentifier("lastName")
                TextField("Nickname", text: $viewModel.nickname).accessibilityIdentifier("nickname")
            }

            Section("Contacts") {
                TextField("Email", text: $viewModel.email)
                    .keyboardType(.emailAddress).accessibilityIdentifier("email")
            }
        }
        .onTapGesture {
            hideKeyboard()
        }
        .overlay(alignment: .bottom) {
            if showSnackbar {
                Text("Profile saved")
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
        .navigationTitle("Profile")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    viewModel.save()
                    hideKeyboard()
                    showSnackbar = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showSnackbar = false
                    }
                }
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    hideKeyboard()
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
