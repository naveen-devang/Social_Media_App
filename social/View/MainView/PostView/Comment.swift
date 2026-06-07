//
//  Comment.swift
//  social
//
//  Created by デバン・ナビーン on 18/04/24.
//

import SwiftUI

import SDWebImageSwiftUI

// Comment struct
struct Comment: Identifiable, Codable {
    var id = UUID()
    var userID: String
    var userName: String
    var userProfileURL: URL?
    var text: String
    var timestamp: Date
    var parentCommentID: UUID?
    var replies: [Comment] = []
    var repliesCount: Int = 0
    var likes: [String] = [] // New field to track likes
    var likesCount: Int { likes.count } // Computed property for like count
    
    enum CodingKeys: String, CodingKey {
        case id, userID, userName, userProfileURL, text, timestamp, parentCommentID, likes
    }
    
    // Update existing initializers to include likes
    init(id: UUID = UUID(), userID: String, userName: String, userProfileURL: URL?, text: String, timestamp: Date, parentCommentID: UUID? = nil, likes: [String] = []) {
        self.id = id
        self.userID = userID
        self.userName = userName
        self.userProfileURL = userProfileURL
        self.text = text
        self.timestamp = timestamp
        self.parentCommentID = parentCommentID
        self.likes = likes
    }
    
    // Update decoder to include likes
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        userID = try container.decode(String.self, forKey: .userID)
        userName = try container.decode(String.self, forKey: .userName)
        text = try container.decode(String.self, forKey: .text)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        parentCommentID = try container.decodeIfPresent(UUID.self, forKey: .parentCommentID)
        likes = try container.decodeIfPresent([String].self, forKey: .likes) ?? []
        
        // Safely decode URL string
        if let urlString = try? container.decode(String.self, forKey: .userProfileURL),
           !urlString.isEmpty {
            userProfileURL = URL(string: urlString)
        } else {
            userProfileURL = nil
        }
    }
    
    // Update encoder to include likes
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(userID, forKey: .userID)
        try container.encode(userName, forKey: .userName)
        try container.encode(text, forKey: .text)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encodeIfPresent(parentCommentID, forKey: .parentCommentID)
        try container.encode(userProfileURL?.absoluteString ?? "", forKey: .userProfileURL)
        try container.encode(likes, forKey: .likes)
    }
}

// CommentsView to display comments
struct CommentsView: View {
    var comments: [Comment]
    var postID: String
    var userID: String
    var userName: String
    var userProfileURL: URL
    var onCommentAdded: () -> Void
    var onCommentUpdated: () -> Void
    var onCommentDeleted: () -> Void
    
    @State private var newCommentText = ""
    @State private var fetchedComments = false
    @State private var editingComment: Comment?
    @State private var replyingToComment: Comment?
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Comments")
                .font(.system(size: 16, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .padding(.top, 8)
            
            Divider()
            
            ScrollView {
                LazyVStack(spacing: 6) {
                    ForEach(topLevelComments()) { comment in
                        CommentThreadView(
                            comment: comment,
                            comments: comments,
                            currentUserID: userID,
                            depth: 0,
                            maxInitialDepth: 2,
                            maxTotalDepth: 5,
                            onReply: { commentToReply in
                                replyingToComment = commentToReply
                                newCommentText = "@\(commentToReply.userName) "
                            },
                            onEdit: { commentToEdit in
                                editingComment = commentToEdit
                                newCommentText = commentToEdit.text
                            },
                            onDelete: deleteComment,
                            onLike: likeComment // Add the new onLike method
                        )

                        .padding(.vertical, 4)
                    }
                }
            }
            
            Divider()
            
            AddCommentView(
                commentText: $newCommentText,
                postID: postID,
                userID: userID,
                editingComment: $editingComment,
                replyingToComment: $replyingToComment,
                onCommentAdded: onCommentAdded,
                onCommentUpdated: onCommentUpdated
            )
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 2)
        .onAppear {
            if !fetchedComments {
                onCommentAdded()
                fetchedComments = true
            }
        }
    }
    
    func likeComment(_ comment: Comment) {
        let db = Firestore.firestore()
        let commentsCollection = db.collection("Posts").document(postID).collection("Comments")
        
        commentsCollection.whereField("id", isEqualTo: comment.id.uuidString).getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error finding comment: \(error)")
                return
            }
            
            guard let document = querySnapshot?.documents.first else {
                print("No matching comment found")
                return
            }
            
            // Toggle like
            let currentUserLiked = comment.likes.contains(userID)
            var updatedLikes = comment.likes
            
            if currentUserLiked {
                updatedLikes.removeAll { $0 == userID }
            } else {
                updatedLikes.append(userID)
            }
            
            document.reference.updateData([
                "likes": updatedLikes
            ]) { error in
                if let error = error {
                    print("Error updating likes: \(error)")
                } else {
                    // Trigger a refresh of comments
                    onCommentUpdated()
                }
            }
        }
    }
    
    func topLevelComments() -> [Comment] {
        return comments.filter { $0.parentCommentID == nil }
    }
    
    func deleteComment(_ comment: Comment) {
        let db = Firestore.firestore()
        let commentsCollection = db.collection("Posts").document(postID).collection("Comments")
        
        commentsCollection.whereField("id", isEqualTo: comment.id.uuidString).getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error finding comment: \(error)")
                return
            }
            
            guard let document = querySnapshot?.documents.first else {
                print("No matching comment found")
                return
            }
            
            document.reference.delete { error in
                if let error = error {
                    print("Error deleting comment: \(error)")
                } else {
                    onCommentDeleted()
                }
            }
        }
    }
}

struct CommentThreadView: View {
    let comment: Comment
    let comments: [Comment]
    let currentUserID: String
    let depth: Int
    var maxInitialDepth = 3 // Initial render depth
    var maxTotalDepth = 6 // Maximum total expanded depth
    var onReply: (Comment) -> Void
    var onEdit: (Comment) -> Void
    var onDelete: (Comment) -> Void
    var onLike: (Comment) -> Void
    
    @State private var isExpanded = false
    
    var replies: [Comment] {
        comments.filter { $0.parentCommentID == comment.id }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                // Vertical connection line for nested comments
                if depth > 0 {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 2, height: 20)
                        .padding(.trailing, 8)
                }
                
                CommentRowView(
                    comment: comment,
                    currentUserID: currentUserID,
                    isReply: depth > 0,
                    onReply: onReply,
                    onEdit: onEdit,
                    onDelete: onDelete,
                    onLike: onLike
                )
            }
            
            // Render replies with depth management
            if depth < maxInitialDepth {
                renderReplies()
            } else {
                deepThreadIndicator()
            }
        }
    }
    
    @ViewBuilder
    func renderReplies() -> some View {
        if !replies.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(replies) { reply in
                    CommentThreadView(
                        comment: reply,
                        comments: comments,
                        currentUserID: currentUserID,
                        depth: depth + 1,
                        maxInitialDepth: maxInitialDepth,
                        maxTotalDepth: maxTotalDepth,
                        onReply: onReply,
                        onEdit: onEdit,
                        onDelete: onDelete,
                        onLike: onLike
                    )
                    .padding(.leading, 20) // Consistent indentation
                }
            }
        }
    }
    
    @ViewBuilder
    func deepThreadIndicator() -> some View {
        if !replies.isEmpty {
            HStack {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 2, height: 20)
                    .padding(.trailing, 8)
                
                Button(action: {
                    // Prevent expansion beyond total depth limit
                    if depth < maxTotalDepth {
                        isExpanded.toggle()
                    }
                }) {
                    HStack {
                        Text("View \(replies.count) more \(replies.count == 1 ? "reply" : "replies")")
                            .font(.footnote)
                            .foregroundColor(.blue)
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.footnote)
                            .foregroundColor(.blue)
                    }
                }
                
                // Add a warning if max depth is reached
                if depth >= maxTotalDepth {
                    Text("Max depth reached")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
            }
            .padding(.leading, 20)
            
            if isExpanded {
                ForEach(replies) { reply in
                    CommentThreadView(
                        comment: reply,
                        comments: comments,
                        currentUserID: currentUserID,
                        depth: depth + 1,
                        maxInitialDepth: maxInitialDepth,
                        maxTotalDepth: maxTotalDepth,
                        onReply: onReply,
                        onEdit: onEdit,
                        onDelete: onDelete,
                        onLike: onLike
                    )
                    .padding(.leading, 40)
                }
            }
        }
    }
}


struct CommentRowView: View {
    let comment: Comment
    let currentUserID: String
    var isReply: Bool = false
    var onReply: (Comment) -> Void
    var onEdit: (Comment) -> Void
    var onDelete: (Comment) -> Void
    var onLike: (Comment) -> Void
    
    var isLikedByCurrentUser: Bool {
        comment.likes.contains(currentUserID)
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            WebImage(url: comment.userProfileURL)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: isReply ? 30 : 40, height: isReply ? 30 : 40)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(comment.userName)
                        .font(.body)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text(formattedDate(for: comment.timestamp))
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                
                Text(comment.text)
                    .font(.footnote)
                    .lineLimit(3)
                
                HStack(spacing: 15) {
                    // Like Button
                    Button(action: { onLike(comment) }) {
                        HStack(spacing: 4) {
                            Image(systemName: isLikedByCurrentUser ? "heart.fill" : "heart")
                                .foregroundColor(isLikedByCurrentUser ? .red : .secondary)
                            
                            if comment.likesCount > 0 {
                                Text("\(comment.likesCount)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Menu {
                        Button(action: { onReply(comment) }) {
                            Text("Reply")
                            Image(systemName: "arrowshape.turn.up.left.fill")
                        }
                        
                        if comment.userID == currentUserID {
                            Button(action: { onEdit(comment) }) {
                                Text("Edit")
                                Image(systemName: "pencil")
                            }
                            
                            Button(role: .destructive, action: { onDelete(comment) }) {
                                Text("Delete")
                                Image(systemName: "trash")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.secondary)
                            .imageScale(.small)
                    }
                }
            }
        }
        .padding(8)
        .background(isReply ? Color.gray.opacity(0.05) : Color.clear)
        .cornerRadius(8)
    }
    
    func formattedDate(for date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        let components = calendar.dateComponents([.day, .hour, .minute, .second], from: date, to: now)
        
        if let days = components.day, days >= 7 {
            let weeks = days / 7
            return "\(weeks) weeks ago"
        } else if let days = components.day, days > 0 {
            return "\(days) days ago"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours) hours ago"
        } else if let minutes = components.minute, minutes > 0 {
            return "\(minutes) minutes ago"
        } else if let months = calendar.dateComponents([.month], from: date, to: now).month, months > 0 {
            return "\(months) months ago"
        } else {
            return "Just now"
        }
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(10) // Adjust padding as needed
            .padding(.leading, 15)
            .padding(.trailing, 15)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(Color.gray, lineWidth: 2) // Change color and line width as needed
                    .opacity(0.8)
            )
    }
}

struct AddCommentView: View {
    @Binding var commentText: String
    var postID: String
    var userID: String
    @Binding var editingComment: Comment?
    @Binding var replyingToComment: Comment?
    var onCommentAdded: () -> Void
    var onCommentUpdated: () -> Void
    
    @State private var userName: String = ""
    @State private var userProfileURL: URL?
    
    var body: some View {
        HStack(spacing: 8) {
            TextField(
                editingComment != nil ? "Edit comment" :
                (replyingToComment != nil ? "Reply to comment" : "Add a comment"),
                text: $commentText
            )
            .textFieldStyle(PlainTextFieldStyle())
            .font(.body)
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(20)
            
            Button(action: editingComment != nil ? updateComment :
                    (replyingToComment != nil ? addReply : addComment)) {
                Text(editingComment != nil ? "Update" :
                     (replyingToComment != nil ? "Reply" : "Post"))
                .font(.body)
                    .foregroundColor(.blue)
            }
            .disabled(commentText.isEmpty)
        }
        .onAppear {
            fetchUserData()
        }
    }
    
    func fetchUserData() {
        let db = Firestore.firestore()
        let userRef = db.collection("Users").document(userID)
        
        userRef.getDocument { snapshot, error in
            if let error = error {
                print("Error fetching user data: \(error)")
                return
            }
            
            if let data = snapshot?.data() {
                self.userName = data["username"] as? String ?? "Unknown"
                if let profileURLString = data["userProfileURL"] as? String,
                   !profileURLString.isEmpty,
                   let url = URL(string: profileURLString) {
                    self.userProfileURL = url
                }
            }
        }
    }
    
    func addComment() {
        guard !commentText.isEmpty else { return }
        
        let newComment = Comment(
            userID: userID,
            userName: userName,
            userProfileURL: userProfileURL,
            text: commentText,
            timestamp: Date()
        )
        
        saveCommentToFirestore(comment: newComment)
    }
    
    func addReply() {
        guard let parentComment = replyingToComment, !commentText.isEmpty else { return }
        
        let newReply = Comment(
            userID: userID,
            userName: userName,
            userProfileURL: userProfileURL,
            text: commentText,
            timestamp: Date(),
            parentCommentID: parentComment.id
        )
        
        saveCommentToFirestore(comment: newReply)
    }
    
    func saveCommentToFirestore(comment: Comment) {
        let db = Firestore.firestore()
        let commentsCollection = db.collection("Posts").document(postID).collection("Comments")
        
        let commentData: [String: Any] = [
            "id": comment.id.uuidString,
            "userID": comment.userID,
            "userName": comment.userName,
            "userProfileURL": comment.userProfileURL?.absoluteString ?? "",
            "text": comment.text,
            "timestamp": comment.timestamp,
            "parentCommentID": comment.parentCommentID?.uuidString ?? NSNull()
        ]
        
        commentsCollection.addDocument(data: commentData) { error in
            if let error = error {
                print("Error adding comment: \(error)")
            } else {
                onCommentAdded()
                commentText = ""
                replyingToComment = nil
                editingComment = nil
            }
        }
    }
    
    func likeComment(_ comment: Comment) {
        let db = Firestore.firestore()
        let commentsCollection = db.collection("Posts").document(postID).collection("Comments")
        
        commentsCollection.whereField("id", isEqualTo: comment.id.uuidString).getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error finding comment: \(error)")
                return
            }
            
            guard let document = querySnapshot?.documents.first else {
                print("No matching comment found")
                return
            }
            
            // Toggle like
            let currentUserLiked = comment.likes.contains(userID)
            var updatedLikes = comment.likes
            
            if currentUserLiked {
                updatedLikes.removeAll { $0 == userID }
            } else {
                updatedLikes.append(userID)
            }
            
            document.reference.updateData([
                "likes": updatedLikes
            ]) { error in
                if let error = error {
                    print("Error updating likes: \(error)")
                } else {
                    // Trigger a refresh of comments
                    onCommentUpdated()
                }
            }
        }
    }
    
    func updateComment() {
        guard let comment = editingComment else { return }
        
        let db = Firestore.firestore()
        let commentsCollection = db.collection("Posts").document(postID).collection("Comments")
        
        commentsCollection.whereField("id", isEqualTo: comment.id.uuidString).getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error finding comment: \(error)")
                return
            }
            
            guard let document = querySnapshot?.documents.first else {
                print("No matching comment found")
                return
            }
            
            document.reference.updateData([
                "text": commentText
            ]) { error in
                if let error = error {
                    print("Error updating comment: \(error)")
                } else {
                    onCommentUpdated()
                    commentText = ""
                    editingComment = nil
                }
            }
        }
    }
}
