//
//  Post.swift
//  social
//

import SwiftUI

//MARK: Post Model
struct Post: Identifiable, Codable, Equatable, Hashable {
    var id: String?
    var text: String
    var imageURL: URL?
    var imageReferenceID: String = ""
    var publishedDate: Date = Date()
    var likedIDs: [String] = []
    var dislikedIDs: [String] = []
    
    //MARK: Basic User Info
    var userName: String
    var userUID: String
    var userProfileURL: URL

    // Memberwise initializer
    init(id: String? = nil, text: String, imageURL: URL? = nil, imageReferenceID: String = "", publishedDate: Date = Date(), likedIDs: [String] = [], dislikedIDs: [String] = [], userName: String, userUID: String, userProfileURL: URL) {
        self.id = id
        self.text = text
        self.imageURL = imageURL
        self.imageReferenceID = imageReferenceID
        self.publishedDate = publishedDate
        self.likedIDs = likedIDs
        self.dislikedIDs = dislikedIDs
        self.userName = userName
        self.userUID = userUID
        self.userProfileURL = userProfileURL
    }

    enum CodingKeys: String, CodingKey {
        case id = "$id"
        case text
        case imageURL
        case imageReferenceID
        case publishedDate
        case likedIDs
        case dislikedIDs
        case userName
        case userUID
        case userProfileURL
    }

    // Custom Decodable to handle ISO8601 dates and provide default values
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        text = try container.decode(String.self, forKey: .text)
        
        // Handle empty or missing URLs/Strings safely
        if let urlStr = try container.decodeIfPresent(String.self, forKey: .imageURL), !urlStr.isEmpty {
            imageURL = URL(string: urlStr)
        } else {
            imageURL = nil
        }
        
        imageReferenceID = try container.decodeIfPresent(String.self, forKey: .imageReferenceID) ?? ""
        
        // Parse publishedDate string to Date
        if let dateString = try container.decodeIfPresent(String.self, forKey: .publishedDate),
           let date = Post.dateFormatter.date(from: dateString) {
            publishedDate = date
        } else {
            publishedDate = Date()
        }
        
        likedIDs = try container.decodeIfPresent([String].self, forKey: .likedIDs) ?? []
        dislikedIDs = try container.decodeIfPresent([String].self, forKey: .dislikedIDs) ?? []
        userName = try container.decode(String.self, forKey: .userName)
        userUID = try container.decode(String.self, forKey: .userUID)
        
        let profileURLStr = try container.decode(String.self, forKey: .userProfileURL)
        userProfileURL = URL(string: profileURLStr) ?? URL(string: "about:blank")!
    }

    // Custom Encodable to serialize Date back to ISO8601 String
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(text, forKey: .text)
        try container.encodeIfPresent(imageURL?.absoluteString, forKey: .imageURL)
        try container.encode(imageReferenceID, forKey: .imageReferenceID)
        
        let dateString = Post.dateFormatter.string(from: publishedDate)
        try container.encode(dateString, forKey: .publishedDate)
        
        try container.encode(likedIDs, forKey: .likedIDs)
        try container.encode(dislikedIDs, forKey: .dislikedIDs)
        try container.encode(userName, forKey: .userName)
        try container.encode(userUID, forKey: .userUID)
        try container.encode(userProfileURL.absoluteString, forKey: .userProfileURL)
    }

    private static let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}
