//
//  CarListing.swift
//  social
//

import Foundation

struct CarListing: Identifiable, Codable {
    var id: String?
    var make: String
    var model: String
    var trim: String
    var year: Int
    var price: Double
    var description: String
    
    // Additional vehicle details
    var mileage: Int
    var fuelType: String
    var transmission: String
    var exteriorColor: String
    var interiorColor: String
    var bodyType: String
    var condition: String
    var features: String
    var location: String
    var contactNumber: String
    
    // New fields
    var vinNumber: String
    var drivetrain: String
    var engine: String
    var sellerType: String
    
    // Seller and image details
    var imageURLs: [URL]
    var sellerUID: String
    var sellerName: String
    var sellerProfileURL: URL?
    var publishedDate: Date
    var lastUpdated: Date

    init(
        id: String? = nil,
        make: String,
        model: String,
        trim: String,
        year: Int,
        price: Double,
        description: String,
        mileage: Int = 0,
        fuelType: String = "",
        transmission: String = "",
        exteriorColor: String = "",
        interiorColor: String = "",
        bodyType: String = "",
        condition: String = "",
        features: String = "",
        location: String = "",
        contactNumber: String = "",
        vinNumber: String = "",
        drivetrain: String = "",
        engine: String = "",
        sellerType: String = "",
        imageURLs: [URL] = [],
        sellerUID: String,
        sellerName: String,
        sellerProfileURL: URL?,
        publishedDate: Date = Date(),
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.make = make
        self.model = model
        self.trim = trim
        self.year = year
        self.price = price
        self.description = description
        self.mileage = mileage
        self.fuelType = fuelType
        self.transmission = transmission
        self.exteriorColor = exteriorColor
        self.interiorColor = interiorColor
        self.bodyType = bodyType
        self.condition = condition
        self.features = features
        self.location = location
        self.contactNumber = contactNumber
        self.vinNumber = vinNumber
        self.drivetrain = drivetrain
        self.engine = engine
        self.sellerType = sellerType
        self.imageURLs = imageURLs
        self.sellerUID = sellerUID
        self.sellerName = sellerName
        self.sellerProfileURL = sellerProfileURL
        self.publishedDate = publishedDate
        self.lastUpdated = lastUpdated
    }

    enum CodingKeys: String, CodingKey {
        case id = "$id"
        case make
        case model
        case trim
        case year
        case price
        case description
        case mileage
        case fuelType
        case transmission
        case exteriorColor
        case interiorColor
        case bodyType
        case condition
        case features
        case location
        case contactNumber
        case vinNumber
        case drivetrain
        case engine
        case sellerType
        case imageURLs
        case sellerUID
        case sellerName
        case sellerProfileURL
        case publishedDate
        case lastUpdated
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        make = try container.decode(String.self, forKey: .make)
        model = try container.decode(String.self, forKey: .model)
        trim = try container.decode(String.self, forKey: .trim)
        year = try container.decode(Int.self, forKey: .year)
        price = try container.decode(Double.self, forKey: .price)
        description = try container.decode(String.self, forKey: .description)
        mileage = try container.decode(Int.self, forKey: .mileage)
        fuelType = try container.decode(String.self, forKey: .fuelType)
        transmission = try container.decode(String.self, forKey: .transmission)
        exteriorColor = try container.decode(String.self, forKey: .exteriorColor)
        interiorColor = try container.decode(String.self, forKey: .interiorColor)
        bodyType = try container.decode(String.self, forKey: .bodyType)
        condition = try container.decode(String.self, forKey: .condition)
        features = try container.decode(String.self, forKey: .features)
        location = try container.decode(String.self, forKey: .location)
        contactNumber = try container.decode(String.self, forKey: .contactNumber)
        vinNumber = try container.decode(String.self, forKey: .vinNumber)
        drivetrain = try container.decode(String.self, forKey: .drivetrain)
        engine = try container.decode(String.self, forKey: .engine)
        sellerType = try container.decode(String.self, forKey: .sellerType)
        
        let urlsStrings = try container.decodeIfPresent([String].self, forKey: .imageURLs) ?? []
        imageURLs = urlsStrings.compactMap { URL(string: $0) }
        
        sellerUID = try container.decode(String.self, forKey: .sellerUID)
        sellerName = try container.decode(String.self, forKey: .sellerName)
        
        if let profileURLString = try container.decodeIfPresent(String.self, forKey: .sellerProfileURL), !profileURLString.isEmpty {
            sellerProfileURL = URL(string: profileURLString)
        } else {
            sellerProfileURL = nil
        }
        
        let pubDateStr = try container.decode(String.self, forKey: .publishedDate)
        publishedDate = CarListing.dateFormatter.date(from: pubDateStr) ?? Date()
        
        let updateDateStr = try container.decode(String.self, forKey: .lastUpdated)
        lastUpdated = CarListing.dateFormatter.date(from: updateDateStr) ?? Date()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(make, forKey: .make)
        try container.encode(model, forKey: .model)
        try container.encode(trim, forKey: .trim)
        try container.encode(year, forKey: .year)
        try container.encode(price, forKey: .price)
        try container.encode(description, forKey: .description)
        try container.encode(mileage, forKey: .mileage)
        try container.encode(fuelType, forKey: .fuelType)
        try container.encode(transmission, forKey: .transmission)
        try container.encode(exteriorColor, forKey: .exteriorColor)
        try container.encode(interiorColor, forKey: .interiorColor)
        try container.encode(bodyType, forKey: .bodyType)
        try container.encode(condition, forKey: .condition)
        try container.encode(features, forKey: .features)
        try container.encode(location, forKey: .location)
        try container.encode(contactNumber, forKey: .contactNumber)
        try container.encode(vinNumber, forKey: .vinNumber)
        try container.encode(drivetrain, forKey: .drivetrain)
        try container.encode(engine, forKey: .engine)
        try container.encode(sellerType, forKey: .sellerType)
        
        let urlsStrings = imageURLs.map { $0.absoluteString }
        try container.encode(urlsStrings, forKey: .imageURLs)
        
        try container.encode(sellerUID, forKey: .sellerUID)
        try container.encode(sellerName, forKey: .sellerName)
        try container.encodeIfPresent(sellerProfileURL?.absoluteString, forKey: .sellerProfileURL)
        
        let pubDateStr = CarListing.dateFormatter.string(from: publishedDate)
        try container.encode(pubDateStr, forKey: .publishedDate)
        
        let updateDateStr = CarListing.dateFormatter.string(from: lastUpdated)
        try container.encode(updateDateStr, forKey: .lastUpdated)
    }

    private static let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}
