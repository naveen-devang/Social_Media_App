//
//  Message.swift
//  social
//

import SwiftUI

struct Message: Identifiable, Codable {
    var id: String?
    var conversationId: String = "" // Added for Appwrite flat collections
    var senderId: String
    var receiverId: String
    var text: String
    var timestamp: Date
    var isRead: Bool
    var reactionType: String? // For future emoji reactions
    
    init(id: String? = nil, conversationId: String = "", senderId: String, receiverId: String, text: String, timestamp: Date, isRead: Bool, reactionType: String? = nil) {
        self.id = id
        self.conversationId = conversationId
        self.senderId = senderId
        self.receiverId = receiverId
        self.text = text
        self.timestamp = timestamp
        self.isRead = isRead
        self.reactionType = reactionType
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "$id"
        case conversationId
        case senderId
        case receiverId
        case text
        case timestamp
        case isRead
        case reactionType
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        conversationId = try container.decodeIfPresent(String.self, forKey: .conversationId) ?? ""
        senderId = try container.decode(String.self, forKey: .senderId)
        receiverId = try container.decode(String.self, forKey: .receiverId)
        text = try container.decode(String.self, forKey: .text)
        
        let dateString = try container.decode(String.self, forKey: .timestamp)
        if let date = Message.dateFormatter.date(from: dateString) {
            timestamp = date
        } else {
            timestamp = Date()
        }
        
        isRead = try container.decode(Bool.self, forKey: .isRead)
        reactionType = try container.decodeIfPresent(String.self, forKey: .reactionType)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(conversationId, forKey: .conversationId)
        try container.encode(senderId, forKey: .senderId)
        try container.encode(receiverId, forKey: .receiverId)
        try container.encode(text, forKey: .text)
        
        let dateString = Message.dateFormatter.string(from: timestamp)
        try container.encode(dateString, forKey: .timestamp)
        
        try container.encode(isRead, forKey: .isRead)
        try container.encodeIfPresent(reactionType, forKey: .reactionType)
    }
    
    private static let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}
