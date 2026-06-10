//
//  ProfileViewModel.swift
//  GameBacklog
//
//  Created by Serhii Pershuta on 10.06.2026.
//

import Foundation
import Combine

class ProfileViewModel: ObservableObject {
    @Published var firstName: String = UserDefaults.standard.string(forKey: "firstName") ?? ""
    @Published var lastName: String = UserDefaults.standard.string(forKey: "lastName") ?? ""
    @Published var nickname: String = UserDefaults.standard.string(forKey: "nickname") ?? ""
    @Published var email: String = UserDefaults.standard.string(forKey: "email") ?? ""

    func save() {
        UserDefaults.standard.set(firstName, forKey: "firstName")
        UserDefaults.standard.set(lastName, forKey: "lastName")
        UserDefaults.standard.set(nickname, forKey: "nickname")
        UserDefaults.standard.set(email, forKey: "email")
    }
}
