//
//  ProfileViewModel.swift
//  GameBacklog
//
//  Created by Serhii Pershuta on 10.06.2026.
//

import Foundation
import Combine

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var nickname: String = ""
    @Published var email: String = ""
    @Published var profilePhotoData: Data?

    private var savedFirstName = ""
    private var savedLastName = ""
    private var savedNickname = ""
    private var savedEmail = ""
    private var savedProfilePhotoData: Data?

    /// Keys these locally-stored fields by account so switching users on the
    /// same device doesn't show one account's name/photo to another —
    /// `"guest"` for signed-out/local-only use.
    private var namespace = "guest"

    var hasChanges: Bool {
        firstName != savedFirstName ||
        lastName != savedLastName ||
        nickname != savedNickname ||
        email != savedEmail ||
        profilePhotoData != savedProfilePhotoData
    }

    init() {
        load(namespace: "guest", migrateLegacy: true)
    }

    /// Switches which account's locally-stored fields are shown, discarding
    /// any unsaved edits for the account being left. Call whenever the
    /// signed-in user changes (including signing out, which maps to `nil`).
    func reload(for userID: UUID?) {
        let newNamespace = userID?.uuidString ?? "guest"
        guard newNamespace != namespace else { return }
        load(namespace: newNamespace, migrateLegacy: false)
    }

    private func load(namespace: String, migrateLegacy: Bool) {
        self.namespace = namespace

        if migrateLegacy {
            Self.migrateLegacyFieldsIfNeeded(into: namespace)
        }

        savedFirstName = UserDefaults.standard.string(forKey: key("firstName")) ?? ""
        savedLastName = UserDefaults.standard.string(forKey: key("lastName")) ?? ""
        savedNickname = UserDefaults.standard.string(forKey: key("nickname")) ?? ""
        savedEmail = UserDefaults.standard.string(forKey: key("email")) ?? ""

        firstName = savedFirstName
        lastName = savedLastName
        nickname = savedNickname
        email = savedEmail

        if migrateLegacy {
            Self.migrateLegacyPhotoIfNeeded(to: avatarFileURL)
        }
        let photoData = try? Data(contentsOf: avatarFileURL)
        savedProfilePhotoData = photoData
        profilePhotoData = photoData
    }

    func save() {
        UserDefaults.standard.set(firstName, forKey: key("firstName"))
        UserDefaults.standard.set(lastName, forKey: key("lastName"))
        UserDefaults.standard.set(nickname, forKey: key("nickname"))
        UserDefaults.standard.set(email, forKey: key("email"))
        if let profilePhotoData {
            try? profilePhotoData.write(to: avatarFileURL, options: .atomic)
        } else {
            try? FileManager.default.removeItem(at: avatarFileURL)
        }

        savedFirstName = firstName
        savedLastName = lastName
        savedNickname = nickname
        savedEmail = email
        savedProfilePhotoData = profilePhotoData
    }

    func cancelChanges() {
        firstName = savedFirstName
        lastName = savedLastName
        nickname = savedNickname
        email = savedEmail
        profilePhotoData = savedProfilePhotoData
    }

    private func key(_ field: String) -> String { "\(field):\(namespace)" }

    /// Avatar images are stored as a file rather than in UserDefaults: UserDefaults
    /// is backed by a plist that's loaded into memory in full at launch, and Apple
    /// explicitly advises against using it for binary blobs.
    private var avatarFileURL: URL {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Profile", isDirectory: true)
            .appendingPathComponent(namespace, isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("avatar.jpg")
    }

    /// One-time migration for the earlier build where these fields weren't
    /// namespaced per account yet — folds them into the "guest" bucket, the
    /// closest equivalent to how they were used before accounts existed.
    private static func migrateLegacyFieldsIfNeeded(into namespace: String) {
        for field in ["firstName", "lastName", "nickname", "email"] {
            guard let legacyValue = UserDefaults.standard.string(forKey: field) else { continue }
            UserDefaults.standard.set(legacyValue, forKey: "\(field):\(namespace)")
            UserDefaults.standard.removeObject(forKey: field)
        }
    }

    /// One-time migration for the earlier build that stored the avatar in UserDefaults.
    private static func migrateLegacyPhotoIfNeeded(to fileURL: URL) {
        guard let legacyData = UserDefaults.standard.data(forKey: "profilePhotoData") else { return }
        try? legacyData.write(to: fileURL, options: .atomic)
        UserDefaults.standard.removeObject(forKey: "profilePhotoData")

        // The pre-namespacing build kept the file flat at ".../Profile/avatar.jpg".
        let legacyFileURL = fileURL.deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("avatar.jpg")
        if let legacyFileData = try? Data(contentsOf: legacyFileURL) {
            try? legacyFileData.write(to: fileURL, options: .atomic)
            try? FileManager.default.removeItem(at: legacyFileURL)
        }
    }
}
