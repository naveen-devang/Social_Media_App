//
//  HashtagPostsView.swift
//  social
//
//  Created by デバン・ナビーン on 24/04/24.
//

import SwiftUI


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
        let db = Firestore.firestore()
        db.collection("Posts")
            .whereField("hashtags", arrayContains: hashtag) // Fetch posts with the specified hashtag
            .order(by: "publishedDate", descending: true) // Sort posts by published date in descending order
            .getDocuments { querySnapshot, error in
                if let error = error {
                    print("Error fetching posts: \(error.localizedDescription)")
                    return
                }

                guard let documents = querySnapshot?.documents else {
                    print("No documents found")
                    return
                }

                self.posts = documents.compactMap { document in
                    do {
                        let postData = try document.data(as: Post.self)
                        return postData
                    } catch {
                        print("Error decoding post: \(error)")
                        return nil
                    }
                }
            }
        }
    }
