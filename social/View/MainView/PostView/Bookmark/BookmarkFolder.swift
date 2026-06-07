//
//  BookmarkFolder.swift
//  social
//

import SwiftUI

struct BookmarkFolder: Codable, Identifiable {
    var id: String
    var name: String
    var bookmarkedPosts: [String] // Array of post IDs
    let createdBy: String
    let createdAt: Date
    
    init(id: String, name: String, bookmarkedPosts: [String], createdBy: String, createdAt: Date) {
        self.id = id
        self.name = name
        self.bookmarkedPosts = bookmarkedPosts
        self.createdBy = createdBy
        self.createdAt = createdAt
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "$id"
        case name
        case bookmarkedPosts
        case createdBy
        case createdAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        bookmarkedPosts = try container.decodeIfPresent([String].self, forKey: .bookmarkedPosts) ?? []
        createdBy = try container.decode(String.self, forKey: .createdBy)
        
        let dateString = try container.decode(String.self, forKey: .createdAt)
        createdAt = BookmarkFolder.dateFormatter.date(from: dateString) ?? Date()
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(bookmarkedPosts, forKey: .bookmarkedPosts)
        try container.encode(createdBy, forKey: .createdBy)
        
        let dateString = BookmarkFolder.dateFormatter.string(from: createdAt)
        try container.encode(dateString, forKey: .createdAt)
    }
    
    // Create a new folder
    static func create(name: String, userUID: String) -> BookmarkFolder {
        return BookmarkFolder(
            id: UUID().uuidString,
            name: name,
            bookmarkedPosts: [],
            createdBy: userUID,
            createdAt: Date()
        )
    }
    
    private static let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}
