//
//  VehicleEdit.swift
//  social
//

import Foundation

struct VehicleEdit: Identifiable, Codable {
    var id: String?
    let vehicleID: String
    let editorUID: String
    let editorName: String
    var editedFields: [EditedField]
    var timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case id = "$id"
        case vehicleID
        case editorUID
        case editorName
        case editedFields
        case timestamp
    }
    
    init(id: String? = nil, vehicleID: String, editorUID: String, editorName: String, editedFields: [EditedField], timestamp: Date = Date()) {
        self.id = id
        self.vehicleID = vehicleID
        self.editorUID = editorUID
        self.editorName = editorName
        self.editedFields = editedFields
        self.timestamp = timestamp
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        vehicleID = try container.decode(String.self, forKey: .vehicleID)
        editorUID = try container.decode(String.self, forKey: .editorUID)
        editorName = try container.decode(String.self, forKey: .editorName)
        
        // Try decoding editedFields as a JSON string first (since Appwrite doesn't support complex maps/arrays of maps natively)
        if let jsonString = try? container.decode(String.self, forKey: .editedFields),
           let data = jsonString.data(using: .utf8) {
            editedFields = (try? JSONDecoder().decode([EditedField].self, from: data)) ?? []
        } else {
            editedFields = (try? container.decode([EditedField].self, forKey: .editedFields)) ?? []
        }
        
        if let dateString = try container.decodeIfPresent(String.self, forKey: .timestamp),
           let date = VehicleEdit.dateFormatter.date(from: dateString) {
            timestamp = date
        } else {
            timestamp = Date()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(vehicleID, forKey: .vehicleID)
        try container.encode(editorUID, forKey: .editorUID)
        try container.encode(editorName, forKey: .editorName)
        
        // Serialize editedFields as a JSON string
        if let data = try? JSONEncoder().encode(editedFields),
           let jsonString = String(data: data, encoding: .utf8) {
            try container.encode(jsonString, forKey: .editedFields)
        } else {
            try container.encode("[]", forKey: .editedFields)
        }
        
        let dateString = VehicleEdit.dateFormatter.string(from: timestamp)
        try container.encode(dateString, forKey: .timestamp)
    }
    
    private static let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}

struct EditedField: Codable, Hashable {
    let fieldName: String
    let previousValue: String
    let newValue: String
}
