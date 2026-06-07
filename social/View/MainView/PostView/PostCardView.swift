//
//  PostCardView.swift
//  social
//

import SwiftUI
import SDWebImageSwiftUI
import Appwrite

struct PostCardView: View {
    var post: Post
    /// - Callbacks
    var onUpdate: (Post)-> ()
    var onDelete: ()-> ()
    /// - View Properties
    @AppStorage("user_UID") private var userUID: String = ""
    @State private var subscription: RealtimeSubscription?
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            WebImage(url: post.userProfileURL)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 35, height: 35)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 6) {
                Text(post.userName)
                    .font(.callout)
                    .fontWeight(.semibold)
                Text(post.publishedDate.formatted(date: .numeric, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.gray)
                Text(post.text)
                    .textSelection(.enabled)
                    .padding(.vertical,8)
                    
                
                /// - Post Image if ANY
                if let postImageURL = post.imageURL {
                    GeometryReader{
                        let size = $0.size
                        WebImage(url: postImageURL)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: size.width, height: size.height)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .frame(height: 200)
                }
                
                PostInteraction()
            }
        }
        .hAlign(.leading)
        .overlay(alignment: .topTrailing, content: {
            /// - Displaying Delete Button if it is the Author of the Post
            if post.userUID == userUID {
                Menu {
                    Button ("Delete Post", role: .destructive, action: deletePost)
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.caption)
                        .rotationEffect(.init(degrees: -90))
                        .foregroundColor(.blue)
                        .padding(8)
                        .contentShape(Rectangle())
                }
                .offset(x: 8)
            }
        })
        .onAppear {
            if subscription == nil {
                guard let postID = post.id else {return}
                let channel = "databases.\(AppwriteManager.shared.databaseId).collections.\(AppwriteManager.shared.postsCollectionId).documents.\(postID)"
                
                subscription = AppwriteManager.shared.realtime.subscribe(channels: [channel]) { response in
                    // If deletion event is received, notify parent view
                    if response.events.contains(where: { $0.contains(".delete") }) {
                        onDelete()
                        return
                    }
                    
                    // If document update payload is available, decode it and callback
                    guard let payload = response.payload else { return }
                    if let data = try? JSONSerialization.data(withJSONObject: payload, options: []),
                       let updatedPost = try? JSONDecoder().decode(Post.self, from: data) {
                        onUpdate(updatedPost)
                    }
                }
            }
        }
        .onDisappear{
            //MARK: Applying Snapshot Listener Only when the Post is Available on the Screen
            // Else Removing the Listener
            if let subscription {
                subscription.unsubscribe()
                self.subscription = nil
            }
        }
    }
    
    //MARK: Like/Dislike Interaction
    @ViewBuilder
    func PostInteraction()->some View{
        HStack(spacing: 6){
            Button (action: likePost) {
                Image(systemName: post.likedIDs.contains(userUID) ? "heart.fill" : "heart")
            }
            
            Text("\(post.likedIDs.count)")
                .font(.caption)
                .foregroundColor(.gray)
            
            Button (action: dislikePost) {
                Image(systemName: post.dislikedIDs.contains(userUID) ? "hand.thumbsdown.fill" : "hand.thumbsdown")
            }
            .padding(.leading,25)
            
            Text("\(post.dislikedIDs.count)")
                .font(.caption)
                .foregroundColor(.gray)
            
        }
        .foregroundColor(.red)
        .padding(.vertical,8)
        
    }
    
    /// - Liking Posts
    func likePost(){
        Task{
            guard let postID = post.id else { return }
            var updatedLikedIDs = post.likedIDs
            var updatedDislikedIDs = post.dislikedIDs
            
            if post.likedIDs.contains(userUID){
                /// Removing User ID from Array
                updatedLikedIDs.removeAll { $0 == userUID }
            } else {
                /// - Adding User ID To Liked Array and Removing out ID from Disliked Array
                updatedLikedIDs.append(userUID)
                updatedDislikedIDs.removeAll { $0 == userUID }
            }
            
            do {
                _ = try await AppwriteManager.shared.databases.updateDocument(
                    databaseId: AppwriteManager.shared.databaseId,
                    collectionId: AppwriteManager.shared.postsCollectionId,
                    documentId: postID,
                    data: [
                        "likedIDs": updatedLikedIDs,
                        "dislikedIDs": updatedDislikedIDs
                    ]
                )
            } catch {
                print("Error updating likes: \(error.localizedDescription)")
            }
        }
    }
    
    /// - Dislike Post
    func dislikePost(){
        Task{
            guard let postID = post.id else { return }
            var updatedLikedIDs = post.likedIDs
            var updatedDislikedIDs = post.dislikedIDs
            
            if post.dislikedIDs.contains(userUID){
                /// Removing User ID from Array
                updatedDislikedIDs.removeAll { $0 == userUID }
            } else {
                /// - Adding User ID To Disliked Array and Removing out ID from Liked Array
                updatedDislikedIDs.append(userUID)
                updatedLikedIDs.removeAll { $0 == userUID }
            }
            
            do {
                _ = try await AppwriteManager.shared.databases.updateDocument(
                    databaseId: AppwriteManager.shared.databaseId,
                    collectionId: AppwriteManager.shared.postsCollectionId,
                    documentId: postID,
                    data: [
                        "likedIDs": updatedLikedIDs,
                        "dislikedIDs": updatedDislikedIDs
                    ]
                )
            } catch {
                print("Error updating dislikes: \(error.localizedDescription)")
            }
        }
    }
    
    /// - Deleting Post
    func deletePost(){
        Task{
            do{
                /// Step 1: Delete Image from Appwrite Storage if Present
                if post.imageReferenceID != ""{
                    let fileId = "post_\(post.imageReferenceID)"
                    try? await AppwriteManager.shared.storage.deleteFile(
                        bucketId: AppwriteManager.shared.bucketId,
                        fileId: fileId
                    )
                }
                
                /// Step 2: Delete Database Document
                guard let postID = post.id else{return}
                _ = try await AppwriteManager.shared.databases.deleteDocument(
                    databaseId: AppwriteManager.shared.databaseId,
                    collectionId: AppwriteManager.shared.postsCollectionId,
                    documentId: postID
                )
            } catch {
                print("Error deleting post: \(error.localizedDescription)")
            }
        }
    }
    
}
