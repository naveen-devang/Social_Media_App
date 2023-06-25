//
//  Post.swift
//  social
//
//  Created by デバン・ナビーン on 23/06/23.
//

import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreSwift

//MARK: Post Model
struct Post: Identifiable, Codable, Equatable, Hashable {
    @DocumentID var id: String?
    var text: String
    var imageURL: URL?
    var imageReferenceID: String = ""
    var publishedDate: Date = Date()
    var likedIDs: [String] = []
    var dislikedIDs: [String] = []
    //MARK: Basic User Infor
    var userName: String
    var userUID: String
    var userProfileURL: URL

    enum CodingKeys: String, CodingKey {
        case id
        case text
        case imageURL
        case imageReferenceID
        case publishedDate
        case likedIDs
        case dislikedIDs
        case userName
        case userUID
        case userProfileURL
    }
}
