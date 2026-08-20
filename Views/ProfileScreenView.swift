//
//  ProfileScreenView.swift
//  GameBacklog
//
//  Created by Serhii Pershuta on 10.06.2026.
//

import SwiftUI
import PhotosUI

struct ProfileScreenView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @StateObject private var viewModel = ProfileViewModel()
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showSnackbar = false
    @State private var cropTarget: CropTarget?
    @State private var showPhotoLoadError = false

    private struct CropTarget: Identifiable {
        let id = UUID()
        let image: UIImage
    }

    var body: some View {
        Form {
            Section {
                VStack(spacing: 12) {
                    profilePhoto

                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label(String(localized: "profile.button.changePhoto"), systemImage: "photo")
                            .font(.subheadline.weight(.semibold))
                    }
                    // Without an explicit style, Form/List extends this
                    // control's tap target to the whole row — including the
                    // photo above it — since it's the only interactive view
                    // in the section. `.plain` limits it to the label itself.
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("changeProfilePhoto")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .listRowBackground(Color.clear)

            Section(String(localized: "profile.section.personalInfo")) {
                LabeledContent(String(localized: "profile.field.firstName")) {
                    TextField(String(localized: "profile.field.firstName"), text: $viewModel.firstName)
                        .multilineTextAlignment(.trailing)
                        .textContentType(.givenName)
                        .submitLabel(.next)
                        .accessibilityIdentifier("firstName")
                }

                LabeledContent(String(localized: "profile.field.lastName")) {
                    TextField(String(localized: "profile.field.lastName"), text: $viewModel.lastName)
                        .multilineTextAlignment(.trailing)
                        .textContentType(.familyName)
                        .submitLabel(.next)
                        .accessibilityIdentifier("lastName")
                }

                LabeledContent(String(localized: "profile.field.nickname")) {
                    TextField(String(localized: "profile.field.nickname"), text: $viewModel.nickname)
                        .multilineTextAlignment(.trailing)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                        .accessibilityIdentifier("nickname")
                }
            }

            Section(String(localized: "profile.section.contacts")) {
                LabeledContent(String(localized: "profile.field.email")) {
                    TextField(String(localized: "profile.field.email"), text: $viewModel.email)
                        .multilineTextAlignment(.trailing)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .accessibilityIdentifier("email")
                }
            }
        }
        .formStyle(.grouped)
        .scrollDismissesKeyboard(.interactively)
        .task(id: selectedPhoto) {
            await loadSelectedPhoto()
        }
        .onChange(of: authViewModel.currentUserID, initial: true) { _, userID in
            viewModel.reload(for: userID)
        }
        .fullScreenCover(item: $cropTarget) { target in
            AvatarCropView(
                image: target.image,
                onCancel: {
                    cropTarget = nil
                },
                onCrop: { croppedData in
                    viewModel.profilePhotoData = croppedData
                    cropTarget = nil
                }
            )
        }
        .alert(String(localized: "profile.photo.loadError.title"), isPresented: $showPhotoLoadError) {
            Button(String(localized: "profile.button.ok"), role: .cancel) {}
        } message: {
            Text(String(localized: "profile.photo.loadError.message"))
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
                .disabled(!viewModel.hasChanges)
            }
            ToolbarItem(placement: .cancellationAction) {
                Button(String(localized: "profile.button.cancel")) {
                    viewModel.cancelChanges()
                    selectedPhoto = nil
                    hideKeyboard()
                }
                .disabled(!viewModel.hasChanges)
            }
        }
    }

    @ViewBuilder
    private var profilePhoto: some View {
        if let profilePhotoData = viewModel.profilePhotoData,
           let image = UIImage(data: profilePhotoData) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 104, height: 104)
                .clipShape(Circle())
                .overlay {
                    Circle()
                        .strokeBorder(Color(.separator), lineWidth: 0.5)
                }
                .accessibilityLabel(String(localized: "profile.photo.accessibilityLabel"))
        } else {
            ZStack {
                Circle()
                    .fill(Color(.tertiarySystemFill))

                Text(profileInitials)
                    .font(.largeTitle.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .frame(width: 104, height: 104)
            .accessibilityLabel(String(localized: "profile.photo.placeholderAccessibilityLabel"))
        }
    }

    private var profileInitials: String {
        let initials = [viewModel.firstName, viewModel.lastName]
            .compactMap { $0.trimmingCharacters(in: .whitespacesAndNewlines).first }
            .map(String.init)
            .joined()

        return initials.isEmpty ? String(localized: "profile.photo.placeholderInitials") : initials.uppercased()
    }

    private func loadSelectedPhoto() async {
        guard let selectedPhoto else { return }
        defer { self.selectedPhoto = nil }

        do {
            guard let data = try await selectedPhoto.loadTransferable(type: Data.self),
                  let image = AvatarImageProcessor.downsampledImage(from: data) else {
                showPhotoLoadError = true
                return
            }
            cropTarget = CropTarget(image: image)
        } catch {
            showPhotoLoadError = true
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
    .environmentObject(AuthViewModel())
}
