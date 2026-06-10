//
//  Profile.swift
//  GameBacklog
//
//  Created by Serhii Pershuta on 10.06.2026.
//

import Foundation

struct Profile: Identifiable {
    let id: UUID = UUID()
    var firstName: String
    var lastName: String
    var nickname: String
    var email: String
    var birthday: Date
    var photoURL: URL?  
}
