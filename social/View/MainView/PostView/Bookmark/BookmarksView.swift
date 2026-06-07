//
//  BookmarksView.swift
//  social
//
//  Created by Naveen Devang on 12/21/24.
//

import SwiftUI
import SDWebImageSwiftUI
import Appwrite

// BookmarkFolderRow.swift
struct BookmarkFolderRow: View {
    let folder: BookmarkFolder
    let userUID: String
    @State private var firstPostImage: URL?
    @State private var validPostCount: Int = 0
    
    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail Image
            if let imageURL = firstPostImage {
                WebImage(url: imageURL)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "bookmark.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: 20))
                    )
            }
            
            // Folder Information
            VStack(alignment: .leading, spacing: 4) {
                Text(folder.name)
                    .font(.headline)
                Text("\(validPostCount) posts")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .task {
            await fetchFirstPostImage()
            await updateValidPostCount()
        }
    }
    
    func updateValidPostCount() async {
        var count = 0
        for postID in folder.bookmarkedPosts {
            do {
                _ = try await AppwriteManager.shared.databases.getDocument(
                    databaseId: AppwriteManager.shared.databaseId,
                    collectionId: AppwriteManager.shared.postsCollectionId,
                    documentId: postID,
                    nestedType: Post.self
                )
                count += 1
            } catch {
                print("Error checking post existence: \(error)")
            }
        }
        
        await MainActor.run {
            self.validPostCount = count
        }
    }
    
    func fetchFirstPostImage() async {
        guard !folder.bookmarkedPosts.isEmpty else { return }
        
        do {
            let firstPostID = folder.bookmarkedPosts[0]
            let doc = try await AppwriteManager.shared.databases.getDocument(
                databaseId: AppwriteManager.shared.databaseId,
                collectionId: AppwriteManager.shared.postsCollectionId,
                documentId: firstPostID,
                nestedType: Post.self
            )
            
            if let firstImageURL = doc.data.imageURL {
                await MainActor.run {
                    self.firstPostImage = firstImageURL
                }
            }
        } catch {
            print("Error fetching first post image: \(error)")
        }
    }
}

// BookmarksView.swift
struct BookmarksView: View {
    @StateObject private var bookmarkManager = BookmarkManager()
    @State private var selectedFolder: BookmarkFolder?
    @State private var showCreateFolder = false
    @State private var newFolderName = ""
    @State private var showDeleteAlert = false
    @State private var folderToDelete: BookmarkFolder?
    let userUID: String
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(bookmarkManager.folders) { folder in
                    NavigationLink(destination: BookmarkedPostsView(folder: folder, userUID: userUID)) {
                        BookmarkFolderRow(folder: folder, userUID: userUID)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            folderToDelete = folder
                            showDeleteAlert = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle("Bookmarks")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showCreateFolder = true
                    }) {
                        Image(systemName: "folder.badge.plus")
                    }
                }
            }
            .alert("Create New Folder", isPresented: $showCreateFolder) {
                TextField("Folder Name", text: $newFolderName)
                Button("Cancel", role: .cancel) { }
                Button("Create") {
                    guard !newFolderName.isEmpty else { return }
                    Task {
                        await bookmarkManager.createFolder(name: newFolderName, userUID: userUID)
                        newFolderName = ""
                    }
                }
            }
            .alert("Delete Folder", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let folder = folderToDelete {
                        Task {
                            await deleteFolder(folder)
                        }
                    }
                }
            } message: {
                Text("Are you sure you want to delete this folder? All bookmarks in this folder will be removed.")
            }
            .task {
                await bookmarkManager.fetchFolders(userUID: userUID)
            }
        }
    }
    
    func deleteFolder(_ folder: BookmarkFolder) async {
        do {
            _ = try await AppwriteManager.shared.databases.deleteDocument(
                databaseId: AppwriteManager.shared.databaseId,
                collectionId: "bookmark_folders",
                documentId: folder.id
            )
            await bookmarkManager.fetchFolders(userUID: userUID)
        } catch {
            print("Error deleting folder: \(error)")
        }
    }
}

// BookmarkedPostsView.swift
struct BookmarkedPostsView: View {
    let folder: BookmarkFolder
    let userUID: String
    @State private var posts: [Post] = []
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if posts.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "bookmark.slash")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("No Bookmarks")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Posts you bookmark will appear here")
                        .font(.callout)
                        .foregroundColor(.gray)
                }
                .hAlign(.center).vAlign(.center)
            } else {
                ScrollView {
                    LazyVStack(spacing: 15) {
                        ForEach(posts) { post in
                            PostCardView(post: post,
                                onUpdate: { updatedPost in
                                    if let index = posts.firstIndex(where: { $0.id == updatedPost.id }) {
                                        posts[index] = updatedPost
                                    }
                                },
                                onDelete: {
                                    posts.removeAll { $0.id == post.id }
                                }
                            )
                            .transition(.opacity)
                        }
                    }
                    .padding(15)
                }
            }
        }
        .navigationTitle(folder.name)
        .task {
            await fetchBookmarkedPosts()
        }
    }
    
    func fetchBookmarkedPosts() async {
        isLoading = true
        do {
            var fetchedPosts: [Post] = []
            
            for postID in folder.bookmarkedPosts {
                do {
                    let doc = try await AppwriteManager.shared.databases.getDocument(
                        databaseId: AppwriteManager.shared.databaseId,
                        collectionId: AppwriteManager.shared.postsCollectionId,
                        documentId: postID,
                        nestedType: Post.self
                    )
                    var post = doc.data
                    post.id = doc.id
                    fetchedPosts.append(post)
                } catch {
                    print("Error fetching post \(postID): \(error)")
                }
            }
            
            // Sort posts by date, newest first
            fetchedPosts.sort { $0.publishedDate > $1.publishedDate }
            
            await MainActor.run {
                self.posts = fetchedPosts
                self.isLoading = false
            }
        } catch {
            print("Error fetching bookmarked posts: \(error)")
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
}
