//
//  Report.swift
//  social
//
//  Created by Naveen Devang on 11/22/24.
//

import SwiftUI

struct Report: Identifiable, Codable {
    var id: String?
    let postID: String
    let reporterUID: String
    let reportedUserUID: String
    let reason: String
    let category: String
    var timestamp: Date
    let status: String // e.g., "pending", "reviewed", "resolved"
    
    enum CodingKeys: String, CodingKey {
        case id = "$id"
        case postID
        case reporterUID
        case reportedUserUID
        case reason
        case category
        case timestamp
        case status
    }
    
    init(id: String? = nil, postID: String, reporterUID: String, reportedUserUID: String, reason: String, category: String, timestamp: Date = Date(), status: String) {
        self.id = id
        self.postID = postID
        self.reporterUID = reporterUID
        self.reportedUserUID = reportedUserUID
        self.reason = reason
        self.category = category
        self.timestamp = timestamp
        self.status = status
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        postID = try container.decode(String.self, forKey: .postID)
        reporterUID = try container.decode(String.self, forKey: .reporterUID)
        reportedUserUID = try container.decode(String.self, forKey: .reportedUserUID)
        reason = try container.decode(String.self, forKey: .reason)
        category = try container.decode(String.self, forKey: .category)
        
        if let dateString = try container.decodeIfPresent(String.self, forKey: .timestamp),
           let date = Report.dateFormatter.date(from: dateString) {
            timestamp = date
        } else {
            timestamp = Date()
        }
        
        status = try container.decode(String.self, forKey: .status)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(postID, forKey: .postID)
        try container.encode(reporterUID, forKey: .reporterUID)
        try container.encode(reportedUserUID, forKey: .reportedUserUID)
        try container.encode(reason, forKey: .reason)
        try container.encode(category, forKey: .category)
        
        let dateString = Report.dateFormatter.string(from: timestamp)
        try container.encode(dateString, forKey: .timestamp)
        
        try container.encode(status, forKey: .status)
    }
    
    private static let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
    
    enum ReportCategory: String, CaseIterable {
        case harassment = "Harassment or Bullying"
        case spam = "Spam or Misleading"
        case inappropriate = "Inappropriate Content"
        case copyright = "Copyright Violation"
        case hate = "Hate Speech"
        case violence = "Violence"
        case other = "Other"
    }
}
