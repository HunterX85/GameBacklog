//
//  SettingsScreenView.swift
//  GameBacklog
//
//  Created by Serhii Pershuta on 12.08.2026.
//

import SwiftUI
import UniformTypeIdentifiers

struct SettingsScreenView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @StateObject private var settingsViewModel = SettingsViewModel()
    @AppStorage(AppearanceMode.storageKey) private var appearanceMode: AppearanceMode = .system
    @FocusState private var focusedField: Field?

    @State private var showingClearCacheConfirmation = false
    @State private var showingImportPicker = false
    @State private var exportedFile: ExportedFile?
    @State private var showingDeleteAccountConfirmation = false
    @State private var isPasswordVisible = false

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

            Section(String(localized: "settings.section.appearance")) {
                Picker(String(localized: "settings.section.appearance"), selection: $appearanceMode) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            Section {
                dataManagementContent
            } header: {
                Text(String(localized: "settings.section.dataManagement"))
            } footer: {
                Text(String(localized: "settings.dataManagement.footer"))
            }

            Section {
                aboutContent
            } header: {
                Text(String(localized: "settings.section.about"))
            } footer: {
                Text(String(localized: "settings.about.attribution"))
            }
        }
        .formStyle(.grouped)
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(String(localized: "tab.settings"))
        .confirmationDialog(
            String(localized: "settings.dataManagement.cache.confirmTitle"),
            isPresented: $showingClearCacheConfirmation,
            titleVisibility: .visible
        ) {
            Button(String(localized: "settings.dataManagement.cache.clear"), role: .destructive) {
                settingsViewModel.clearCoverCache()
            }
        } message: {
            Text(String(localized: "settings.dataManagement.cache.confirmMessage"))
        }
        .fileImporter(isPresented: $showingImportPicker, allowedContentTypes: [.json]) { result in
            switch result {
            case .success(let url):
                Task { await settingsViewModel.importBacklog(from: url) }
            case .failure(let error):
                settingsViewModel.reportPickerFailure(error)
            }
        }
        .sheet(item: $exportedFile) { file in
            ShareSheet(activityItems: [file.url])
        }
        .confirmationDialog(
            String(localized: "settings.account.deleteAccount.confirmTitle"),
            isPresented: $showingDeleteAccountConfirmation,
            titleVisibility: .visible
        ) {
            Button(String(localized: "settings.account.deleteAccount"), role: .destructive) {
                Task { await authViewModel.deleteAccount() }
            }
        } message: {
            Text(String(localized: "settings.account.deleteAccount.confirmMessage"))
        }
    }

    // MARK: Account

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

        Button(role: .destructive) {
            showingDeleteAccountConfirmation = true
        } label: {
            Text(String(localized: "settings.account.deleteAccount"))
        }
        .disabled(authViewModel.isLoading)
        .accessibilityIdentifier("deleteAccount")

        if let errorMessage = authViewModel.errorMessage {
            Text(errorMessage)
                .font(.footnote)
                .foregroundStyle(.red)
        }
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
            // A List row's own tap gesture competes with the TextField's for
            // the first tap, so tapping empty row space next to short/empty
            // text sometimes just selects the row instead of focusing it.
            // Driving focus explicitly here makes the whole row responsive.
            .contentShape(Rectangle())
            .onTapGesture { focusedField = .email }

        ZStack(alignment: .trailing) {
            // Both fields stay mounted and overlap, toggling visibility
            // rather than swapping one out for the other — swapping would
            // give SecureField and TextField different view identities and
            // drop keyboard focus every time the eye button is tapped.
            Group {
                if isPasswordVisible {
                    TextField(String(localized: "settings.account.password"), text: $authViewModel.password)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } else {
                    SecureField(String(localized: "settings.account.password"), text: $authViewModel.password)
                }
            }
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
            .contentShape(Rectangle())
            .onTapGesture { focusedField = .password }
            .padding(.trailing, 28)

            Button {
                isPasswordVisible.toggle()
            } label: {
                Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(String(localized: isPasswordVisible ? "settings.account.hidePassword" : "settings.account.showPassword"))
            .accessibilityIdentifier("togglePasswordVisibility")
        }

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

    // MARK: Data management

    @ViewBuilder
    private var dataManagementContent: some View {
        LabeledContent(String(localized: "settings.dataManagement.cache.label"), value: settingsViewModel.formattedCacheSize)

        Button(role: .destructive) {
            showingClearCacheConfirmation = true
        } label: {
            Text(String(localized: "settings.dataManagement.cache.clear"))
        }
        .disabled(settingsViewModel.cacheByteCount == 0)

        Button {
            Task { await exportBacklog() }
        } label: {
            HStack {
                Text(String(localized: "settings.dataManagement.export"))
                if settingsViewModel.isExporting {
                    Spacer()
                    ProgressView()
                }
            }
        }
        .disabled(settingsViewModel.isExporting)
        .accessibilityIdentifier("exportBacklog")

        Button {
            showingImportPicker = true
        } label: {
            HStack {
                Text(String(localized: "settings.dataManagement.import"))
                if settingsViewModel.isImporting {
                    Spacer()
                    ProgressView()
                }
            }
        }
        .disabled(settingsViewModel.isImporting)
        .accessibilityIdentifier("importBacklog")

        if let lastImportedCount = settingsViewModel.lastImportedCount {
            Text("^[\(lastImportedCount) game](inflect: true) imported.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }

        if let errorMessage = settingsViewModel.errorMessage {
            Text(errorMessage)
                .font(.footnote)
                .foregroundStyle(.red)
        }
    }

    private func exportBacklog() async {
        guard let url = await settingsViewModel.exportBacklog() else { return }
        exportedFile = ExportedFile(url: url)
    }

    // MARK: About

    @ViewBuilder
    private var aboutContent: some View {
        LabeledContent(String(localized: "settings.about.version"), value: appVersionString)

        Link(destination: URL(string: "https://www.igdb.com")!) {
            externalLinkRow(String(localized: "settings.about.igdb"))
        }

        Link(destination: URL(string: "https://github.com/supabase/supabase-swift")!) {
            externalLinkRow(String(localized: "settings.about.supabase"))
        }
    }

    private func externalLinkRow(_ title: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.primary)
            Spacer()
            Image(systemName: "arrow.up.forward")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var appVersionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(version) (\(build))"
    }
}

// MARK: - Export share sheet

private struct ExportedFile: Identifiable {
    let id = UUID()
    let url: URL
}

/// Thin wrapper presenting `UIActivityViewController` — SwiftUI's `ShareLink`
/// can't be triggered programmatically after an async export completes, so
/// this is driven by `.sheet(item:)` instead.
private struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        // On iPad this presents as a popover, which crashes at runtime unless
        // it has an anchor — this app builds for iPad too (TARGETED_DEVICE_FAMILY
        // includes 2), so the anchor can't be skipped as iPhone-only dead code.
        if let popover = controller.popoverPresentationController {
            let window = UIApplication.shared.connectedScenes
                .compactMap { ($0 as? UIWindowScene)?.keyWindow }
                .first
            popover.sourceView = window
            popover.sourceRect = CGRect(x: window?.bounds.midX ?? 0, y: window?.bounds.midY ?? 0, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        SettingsScreenView()
    }
    .environmentObject(AuthViewModel())
}
