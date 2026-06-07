//
//  AppwriteManager.swift
//  social
//

import Foundation
import Appwrite

class AppwriteManager {
    static let shared = AppwriteManager()
    
    let client: Client
    let account: Account
    let databases: Databases
    let storage: Storage
    let realtime: Realtime
    
    // Config IDs
    let databaseId = "default"
    let usersCollectionId = "users"
    let postsCollectionId = "posts"
    let bucketId = "profile-images" // Single bucket used for both profile and post images
    
    private init() {
        self.client = Client()
            .setEndpoint("https://fra.cloud.appwrite.io/v1")
            .setProject("6a2343d800241dfbbfd0")
        
        self.account = Account(client)
        self.databases = Databases(client)
        self.storage = Storage(client)
        self.realtime = Realtime(client)
    }
}

// Extension to serialize Codable structs to [String: Any] for Appwrite database input
extension Encodable {
    var toDictionary: [String: Any] {
        guard let data = try? JSONEncoder().encode(self) else { return [:] }
        let dict = (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)) as? [String: Any]
        
        // Appwrite metadata fields like $id must NOT be sent during document creation/update
        var cleanDict = dict ?? [:]
        cleanDict.removeValue(forKey: "$id")
        cleanDict.removeValue(forKey: "$createdAt")
        cleanDict.removeValue(forKey: "$updatedAt")
        cleanDict.removeValue(forKey: "$permissions")
        cleanDict.removeValue(forKey: "$databaseId")
        cleanDict.removeValue(forKey: "$collectionId")
        return cleanDict
    }
}
