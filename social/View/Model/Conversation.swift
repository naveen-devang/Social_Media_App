//
//  Conversation.swift
//  social
//

import SwiftUI

struct Conversation: Identifiable, Codable {
    var id: String?
    var participants: [String] // UIDs of users in the conversation
    var lastMessage: String
    var lastMessageTimestamp: Date
    var lastMessageSenderId: String
    var unreadCount: [String: Int] // Dictionary with userUID as key and unread count as value
    
    init(id: String? = nil, participants: [String], lastMessage: String, lastMessageTimestamp: Date, lastMessageSenderId: String, unreadCount: [String: Int]) {
        self.id = id
        self.participants = participants
        self.lastMessage = lastMessage
        self.lastMessageTimestamp = lastMessageTimestamp
        self.lastMessageSenderId = lastMessageSenderId
        self.unreadCount = unreadCount
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "$id"
        case participants
        case lastMessage
        case lastMessageTimestamp
        case lastMessageSenderId
        case unreadCount
    }
    
    // Custom Decodable to handle ISO8601 dates and unreadCount dictionary deserialization from string
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        participants = try container.decodeIfPresent([String].self, forKey: .participants) ?? []
        lastMessage = try container.decode(String.self, forKey: .lastMessage)
        
        let dateString = try container.decode(String.self, forKey: .lastMessageTimestamp)
        if let date = Conversation.dateFormatter.date(from: dateString) {
            lastMessageTimestamp = date
        } else {
            lastMessageTimestamp = Date()
        }
        
        lastMessageSenderId = try container.decode(String.self, forKey: .lastMessageSenderId)
        
        // Decode unreadCount from JSON string since Appwrite doesn't have a map type
        if let unreadCountString = try container.decodeIfPresent(String.self, forKey: .unreadCount),
           let data = unreadCountString.data(using: .utf8),
           let dict = try? JSONDecoder().decode([String: Int].self, from: data) {
            unreadCount = dict
        } else {
            unreadCount = [:]
        }
    }
    
    // Custom Encodable to serialize date and unreadCount dictionary to JSON string
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(participants, forKey: .participants)
        try container.encode(lastMessage, forKey: .lastMessage)
        
        let dateString = Conversation.dateFormatter.string(from: lastMessageTimestamp)
        try container.encode(dateString, forKey: .lastMessageTimestamp)
        
        try container.encode(lastMessageSenderId, forKey: .lastMessageSenderId)
        
        // Encode unreadCount dictionary to string
        if let data = try? JSONEncoder().encode(unreadCount),
           let unreadCountString = String(data: data, encoding: .utf8) {
            try container.encode(unreadCountString, forKey: .unreadCount)
        } else {
            try container.encode("{}", forKey: .unreadCount)
        }
    }
    
    private static let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}
