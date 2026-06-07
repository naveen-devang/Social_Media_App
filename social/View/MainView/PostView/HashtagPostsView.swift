//
//  HashtagPostsView.swift
//  social
//
//  Created by デバン・ナビーン on 24/04/24.
//

import SwiftUI
import Appwrite

struct HashtagPostsView: View {
    let hashtag: String
    @State private var posts: [Post] = [] // Array to hold fetched posts
    @State private var updatedPost: Post? // Property to store the updated post

    var body: some View {
        ScrollView {
            VStack(spacing: 12) { // Adjust spacing as needed
                ForEach(posts, id: \.id) { post in
                    PostCardView(
                        post: post,
                        onUpdate: { updatedPost in
                            // Handle updated post if needed
                            self.updatedPost = updatedPost // Store the updated post
                        },
                        onDelete: {
                            // Handle post deletion if needed
                        }
                    )
                }
            }
            .padding()
        }
        .onAppear {
            if !hashtag.isEmpty {
                fetchPosts()
            }
        }
        .navigationTitle("\(hashtag)") // Set the navigation title to the hashtag name
    }
    

    func fetchPosts() {
        Task {
            do {
                let result = try await AppwriteManager.shared.databases.listDocuments(
                    databaseId: AppwriteManager.shared.databaseId,
                    collectionId: AppwriteManager.shared.postsCollectionId,
                    queries: [
                        Query.contains("hashtags", value: [hashtag]),
                        Query.orderDesc("publishedDate")
                    ],
                    nestedType: Post.self
                )
                
                let fetchedPosts = result.documents.map { doc -> Post in
                    var p = doc.data
                    p.id = doc.id
                    return p
                }
                
                await MainActor.run {
                    self.posts = fetchedPosts
                }
            } catch {
                print("Error fetching posts for hashtag \(hashtag): \(error.localizedDescription)")
            }
        }
    }
}
