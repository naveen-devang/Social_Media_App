//
//  AppNotification.swift
//  social
//

import SwiftUI

struct AppNotification: Identifiable, Codable {
    var id: String?
    var userUID: String = "" // Target user of this notification
    var type: String
    var title: String
    var message: String
    var timestamp: Date
    var read: Bool
    var postID: String
    var reportID: String
    var reportReason: String
    var reportCategory: String
    
    init(id: String? = nil, userUID: String = "", type: String, title: String, message: String, timestamp: Date, read: Bool, postID: String, reportID: String, reportReason: String, reportCategory: String) {
        self.id = id
        self.userUID = userUID
        self.type = type
        self.title = title
        self.message = message
        self.timestamp = timestamp
        self.read = read
        self.postID = postID
        self.reportID = reportID
        self.reportReason = reportReason
        self.reportCategory = reportCategory
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "$id"
        case userUID
        case type
        case title
        case message
        case timestamp
        case read
        case postID
        case reportID
        case reportReason
        case reportCategory
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        userUID = try container.decodeIfPresent(String.self, forKey: .userUID) ?? ""
        type = try container.decode(String.self, forKey: .type)
        title = try container.decode(String.self, forKey: .title)
        message = try container.decode(String.self, forKey: .message)
        
        let dateString = try container.decode(String.self, forKey: .timestamp)
        timestamp = AppNotification.dateFormatter.date(from: dateString) ?? Date()
        
        read = try container.decode(Bool.self, forKey: .read)
        postID = try container.decodeIfPresent(String.self, forKey: .postID) ?? ""
        reportID = try container.decodeIfPresent(String.self, forKey: .reportID) ?? ""
        reportReason = try container.decodeIfPresent(String.self, forKey: .reportReason) ?? ""
        reportCategory = try container.decodeIfPresent(String.self, forKey: .reportCategory) ?? ""
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(userUID, forKey: .userUID)
        try container.encode(type, forKey: .type)
        try container.encode(title, forKey: .title)
        try container.encode(message, forKey: .message)
        
        let dateString = AppNotification.dateFormatter.string(from: timestamp)
        try container.encode(dateString, forKey: .timestamp)
        
        try container.encode(read, forKey: .read)
        try container.encode(postID, forKey: .postID)
        try container.encode(reportID, forKey: .reportID)
        try container.encode(reportReason, forKey: .reportReason)
        try container.encode(reportCategory, forKey: .reportCategory)
    }
    
    private static let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}
