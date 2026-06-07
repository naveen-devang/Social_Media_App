//
//  BookmarkManager.swift
//  social
//

import SwiftUI
import Appwrite

// BookmarkManager.swift
@MainActor class BookmarkManager: ObservableObject {
    @Published var folders: [BookmarkFolder] = []
    @Published var isBookmarked = false
    private var subscription: RealtimeSubscription?
    
    func setupBookmarkListener(userUID: String, postID: String) {
        // Remove existing listener if any
        Task { try? await subscription?.close() }
        
        Task {
            do {
                // Initial fetch
                let result = try await AppwriteManager.shared.databases.listDocuments(
                    databaseId: AppwriteManager.shared.databaseId,
                    collectionId: "bookmark_folders",
                    queries: [
                        Query.equal("createdBy", value: userUID)
                    ],
                    nestedType: BookmarkFolder.self
                )
                
                self.folders = result.documents.map { doc -> BookmarkFolder in
                    var folder = doc.data
                    folder.id = doc.id
                    return folder
                }
                
                self.isBookmarked = self.folders.contains { folder in
                    folder.bookmarkedPosts.contains(postID)
                }
                
                // Set up Appwrite Realtime listener
                let channel = "databases.\(AppwriteManager.shared.databaseId).collections.bookmark_folders.documents"
                subscription = try await AppwriteManager.shared.realtime.subscribe(channels: [channel]) { [weak self] response in
                    guard let self = self else { return }
                    
                    if (response.events ?? []).contains(where: { $0.contains(".delete") }) {
                        guard let payload = response.payload, let deletedId = payload["$id"] as? String else { return }
                        Task { @MainActor in
                            self.folders.removeAll { $0.id == deletedId }
                            self.isBookmarked = self.folders.contains { folder in
                                folder.bookmarkedPosts.contains(postID)
                            }
                        }
                        return
                    }
                    
                    guard let payload = response.payload else { return }
                    if let data = try? JSONSerialization.data(withJSONObject: payload, options: []),
                       var updatedFolder = try? JSONDecoder().decode(BookmarkFolder.self, from: data) {
                        
                        guard updatedFolder.createdBy == userUID else { return }
                        updatedFolder.id = payload["$id"] as? String ?? updatedFolder.id
                        
                        Task { @MainActor in
                            if let idx = self.folders.firstIndex(where: { $0.id == updatedFolder.id }) {
                                self.folders[idx] = updatedFolder
                            } else {
                                self.folders.append(updatedFolder)
                            }
                            
                            self.isBookmarked = self.folders.contains { folder in
                                folder.bookmarkedPosts.contains(postID)
                            }
                        }
                    }
                }
            } catch {
                print("Error setting up bookmark listener: \(error.localizedDescription)")
            }
        }
    }
    
    func removeListener() {
        Task { try? await subscription?.close() }
        subscription = nil
    }
    
    func fetchFolders(userUID: String) async {
        do {
            let result = try await AppwriteManager.shared.databases.listDocuments(
                databaseId: AppwriteManager.shared.databaseId,
                collectionId: "bookmark_folders",
                queries: [
                    Query.equal("createdBy", value: userUID)
                ],
                nestedType: BookmarkFolder.self
            )
            
            self.folders = result.documents.map { doc -> BookmarkFolder in
                var folder = doc.data
                folder.id = doc.id
                return folder
            }
        } catch {
            print("Error fetching bookmark folders: \(error.localizedDescription)")
        }
    }
    
    func createFolder(name: String, userUID: String) async {
        let newFolder = BookmarkFolder.create(name: name, userUID: userUID)
        do {
            _ = try await AppwriteManager.shared.databases.createDocument(
                databaseId: AppwriteManager.shared.databaseId,
                collectionId: "bookmark_folders",
                documentId: newFolder.id,
                data: newFolder.toDictionary
            )
            
            await fetchFolders(userUID: userUID)
        } catch {
            print("Error creating bookmark folder: \(error.localizedDescription)")
        }
    }
    
    func addBookmark(postID: String, folderID: String, userUID: String) async {
        do {
            let doc = try await AppwriteManager.shared.databases.getDocument(
                databaseId: AppwriteManager.shared.databaseId,
                collectionId: "bookmark_folders",
                documentId: folderID,
                nestedType: BookmarkFolder.self
            )
            var folder = doc.data
            if !folder.bookmarkedPosts.contains(postID) {
                folder.bookmarkedPosts.append(postID)
                _ = try await AppwriteManager.shared.databases.updateDocument(
                    databaseId: AppwriteManager.shared.databaseId,
                    collectionId: "bookmark_folders",
                    documentId: folderID,
                    data: [
                        "bookmarkedPosts": folder.bookmarkedPosts
                    ]
                )
            }
            
            await fetchFolders(userUID: userUID)
        } catch {
            print("Error adding bookmark: \(error.localizedDescription)")
        }
    }
    
    func removeBookmark(postID: String, folderID: String, userUID: String) async {
        do {
            let doc = try await AppwriteManager.shared.databases.getDocument(
                databaseId: AppwriteManager.shared.databaseId,
                collectionId: "bookmark_folders",
                documentId: folderID,
                nestedType: BookmarkFolder.self
            )
            var folder = doc.data
            if folder.bookmarkedPosts.contains(postID) {
                folder.bookmarkedPosts.removeAll { $0 == postID }
                _ = try await AppwriteManager.shared.databases.updateDocument(
                    databaseId: AppwriteManager.shared.databaseId,
                    collectionId: "bookmark_folders",
                    documentId: folderID,
                    data: [
                        "bookmarkedPosts": folder.bookmarkedPosts
                    ]
                )
            }
            
            await fetchFolders(userUID: userUID)
        } catch {
            print("Error removing bookmark: \(error.localizedDescription)")
        }
    }
}
