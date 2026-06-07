//
//  BookmarkFolderView.swift
//  social
//
//  Created by Naveen Devang on 12/21/24.
//

import SwiftUI


// BookmarkFolderView.swift
struct BookmarkFolderView: View {
    let userUID: String
    let postID: String
    @ObservedObject var bookmarkManager: BookmarkManager
    @State private var showCreateFolder = false
    @State private var newFolderName = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List(bookmarkManager.folders) { folder in
                Button(action: {
                    Task {
                        await toggleBookmark(in: folder)
                    }
                }) {
                    HStack {
                        BookmarkFolderRow(folder: folder, userUID: userUID)
                        Spacer()
                        if folder.bookmarkedPosts.contains(postID) {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationBarTitle("Save to Folder")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showCreateFolder = true }) {
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
        }
    }
    
    func toggleBookmark(in folder: BookmarkFolder) async {
        if folder.bookmarkedPosts.contains(postID) {
            await bookmarkManager.removeBookmark(postID: postID, folderID: folder.id, userUID: userUID)
        } else {
            await bookmarkManager.addBookmark(postID: postID, folderID: folder.id, userUID: userUID)
        }
        dismiss()
    }
}
