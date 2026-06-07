//
//  Report.swift
//  social
//
//  Created by Naveen Devang on 11/22/24.
//

import SwiftUI

struct Report: Codable {
    let id: String?
    let postID: String
    let reporterUID: String
    let reportedUserUID: String
    let reason: String
    let category: String
    let timestamp: Date
    let status: String // e.g., "pending", "reviewed", "resolved"
    
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
