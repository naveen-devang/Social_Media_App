//
//  User.swift
//  social
//

import SwiftUI

struct User: Identifiable, Codable {
    var id: String?
    var username: String
    var userBio: String
    var userBioLink: String
    var userUID: String
    var userEmail: String
    var userProfileURL: URL
    var blockedUsers: [String]? // Array of userUIDs blocked by this user
    
    enum CodingKeys: String, CodingKey {
        case id = "$id"
        case username
        case userBio
        case userBioLink
        case userUID
        case userEmail
        case userProfileURL
        case blockedUsers
      }
}
