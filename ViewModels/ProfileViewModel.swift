//
//  ProfileViewModel.swift
//  GameBacklog
//
//  Created by Serhii Pershuta on 10.06.2026.
//

import Foundation
import Combine

class ProfileViewModel: ObservableObject {
    @Published var firstName: String
    @Published var lastName: String
    @Published var nickname: String
    @Published var email: String
    @Published var profilePhotoData: Data?

    private var savedFirstName: String
    private var savedLastName: String
    private var savedNickname: String
    private var savedEmail: String
    private var savedProfilePhotoData: Data?

    /// Avatar images are stored as a file rather than in UserDefaults: UserDefaults
    /// is backed by a plist that's loaded into memory in full at launch, and Apple
    /// explicitly advises against using it for binary blobs.
    private let avatarFileURL: URL = {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Profile", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("avatar.jpg")
    }()

    var hasChanges: Bool {
        firstName != savedFirstName ||
        lastName != savedLastName ||
        nickname != savedNickname ||
        email != savedEmail ||
        profilePhotoData != savedProfilePhotoData
    }

    init() {
        savedFirstName = UserDefaults.standard.string(forKey: "firstName") ?? ""
        savedLastName = UserDefaults.standard.string(forKey: "lastName") ?? ""
        savedNickname = UserDefaults.standard.string(forKey: "nickname") ?? ""
        savedEmail = UserDefaults.standard.string(forKey: "email") ?? ""

        firstName = savedFirstName
        lastName = savedLastName
        nickname = savedNickname
        email = savedEmail

        Self.migrateLegacyPhotoIfNeeded(to: avatarFileURL)
        let photoData = try? Data(contentsOf: avatarFileURL)
        savedProfilePhotoData = photoData
        profilePhotoData = photoData
    }

    func save() {
        UserDefaults.standard.set(firstName, forKey: "firstName")
        UserDefaults.standard.set(lastName, forKey: "lastName")
        UserDefaults.standard.set(nickname, forKey: "nickname")
        UserDefaults.standard.set(email, forKey: "email")
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

    /// One-time migration for the earlier build that stored the avatar in UserDefaults.
    private static func migrateLegacyPhotoIfNeeded(to fileURL: URL) {
        guard let legacyData = UserDefaults.standard.data(forKey: "profilePhotoData") else { return }
        try? legacyData.write(to: fileURL, options: .atomic)
        UserDefaults.standard.removeObject(forKey: "profilePhotoData")
    }

    func cancelChanges() {
        firstName = savedFirstName
        lastName = savedLastName
        nickname = savedNickname
        email = savedEmail
        profilePhotoData = savedProfilePhotoData
    }
}
