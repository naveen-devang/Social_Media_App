//
//  Vehicle.swift
//  social
//

import SwiftUI

struct Vehicle: Identifiable, Codable {
    var id: String?
    var manufacturer: String
    var model: String
    var year: Int
    var interiorColor: String
    var exteriorColor: String
    var vinNumber: String
    var mileage: Int
    var engine: String
    var description: String
    var ownerUID: String // UID of the user who owns the vehicle
    var imageUrls: [String]? // Array to store image URLs
    var vehicleID: String
    var isActive: Bool = true  // New field to track if the vehicle is active in a user's garage
    
    enum CodingKeys: String, CodingKey {
        case id = "$id"
        case manufacturer
        case model
        case year
        case interiorColor
        case exteriorColor
        case vinNumber
        case mileage
        case engine
        case description
        case ownerUID
        case imageUrls // Add imageUrls property
        case vehicleID
        case isActive
    }
}
