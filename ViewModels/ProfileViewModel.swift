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
        savedProfilePhotoData = UserDefaults.standard.data(forKey: "profilePhotoData")

        firstName = savedFirstName
        lastName = savedLastName
        nickname = savedNickname
        email = savedEmail
        profilePhotoData = savedProfilePhotoData
    }

    func save() {
        UserDefaults.standard.set(firstName, forKey: "firstName")
        UserDefaults.standard.set(lastName, forKey: "lastName")
        UserDefaults.standard.set(nickname, forKey: "nickname")
        UserDefaults.standard.set(email, forKey: "email")
        if let profilePhotoData {
            UserDefaults.standard.set(profilePhotoData, forKey: "profilePhotoData")
        } else {
            UserDefaults.standard.removeObject(forKey: "profilePhotoData")
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
}
