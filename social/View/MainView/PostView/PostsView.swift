//
//  PostsView.swift
//  social
//
//  Created by デバン・ナビーン on 22/06/23.
//

import SwiftUI


struct PostsView: View {
    @StateObject private var viewModel = PostsViewModel()
    @State private var createNewPost: Bool = false
    let currentUserUID: String = Auth.auth().currentUser?.uid ?? "" // Assuming the user is authenticated
    
    var body: some View {
        NavigationStack {
            if #available(iOS 17.0, *) {
                Group {
                    if viewModel.isLoading {
                        ProgressView()
                    } else if viewModel.followedPosts.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "text.bubble")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text("No Posts")
                                .font(.title2)
                                .fontWeight(.semibold)
                            Text("Follow some users to see their posts here")
                                .font(.callout)
                                .foregroundColor(.gray)
                        }
                    } else {
                        ReusablePostsView(posts: $viewModel.followedPosts)
                    }
                }
                .hAlign(.center).vAlign(.center)
                .overlay(alignment: .bottomTrailing) {
                    if #available(iOS 26.0, *) {
                        Button {
                            createNewPost.toggle()
                        } label: {
                            Image(systemName: "plus")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(13)
                                .glassEffect(.regular.tint(.blue))
                        }
                        .padding(15)
                    } else {
                        // Fallback on earlier versions
                        Button {
                            createNewPost.toggle()
                        } label: {
                            Image(systemName: "plus")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(13)
                                .background(.blue, in: Circle())
                        }
                        .padding(15)
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack(spacing: 20) {
                            NavigationLink {
                                NotificationsView(userUID: currentUserUID) // Navigate to NotificationsView
                            } label: {
                                Image(systemName: "bell")
                                    .foregroundColor(.blue)
                                    .scaleEffect(0.9)
                            }
                            
                            NavigationLink {
                                SearchUserView()
                            } label: {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.blue)
                                    .scaleEffect(0.9)
                            }
                        }
                    }
                }
                .toolbarTitleDisplayMode(.inlineLarge)
                .navigationTitle("Feed")
            } else {
                // Fallback on earlier versions
                Group {
                    if viewModel.isLoading {
                        ProgressView()
                    } else if viewModel.followedPosts.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "text.bubble")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text("No Posts")
                                .font(.title2)
                                .fontWeight(.semibold)
                            Text("Follow some users to see their posts here")
                                .font(.callout)
                                .foregroundColor(.gray)
                        }
                    } else {
                        ReusablePostsView(posts: $viewModel.followedPosts)
                    }
                }
                .hAlign(.center).vAlign(.center)
                .overlay(alignment: .bottomTrailing) {
                    if #available(iOS 26.0, *) {
                        Button {
                            createNewPost.toggle()
                        } label: {
                            Image(systemName: "plus")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(13)
                                .glassEffect(.regular.tint(.blue))
                        }
                        .padding(15)
                    } else {
                        // Fallback on earlier versions
                        Button {
                            createNewPost.toggle()
                        } label: {
                            Image(systemName: "plus")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(13)
                                .background(.blue, in: Circle())
                        }
                        .padding(15)
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack(spacing: 20) {
                            NavigationLink {
                                NotificationsView(userUID: currentUserUID) // Navigate to NotificationsView
                            } label: {
                                Image(systemName: "bell")
                                    .foregroundColor(.blue)
                                    .scaleEffect(0.9)
                            }
                            
                            NavigationLink {
                                SearchUserView()
                            } label: {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.blue)
                                    .scaleEffect(0.9)
                            }
                        }
                    }
                }
                .navigationTitle("Feed")
            }
        }
        .sheet(isPresented: $createNewPost) {
            CreateNewPost { post in
                viewModel.followedPosts.insert(post, at: 0)
            }
        }
        .task {
            await viewModel.fetchFollowedPosts()
        }
    }
}

class PostsViewModel: ObservableObject {
    @Published var followedPosts: [Post] = []
    @Published var isLoading: Bool = false
    
    @MainActor
    func fetchFollowedPosts() async {
        guard let currentUserUID = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        
        do {
            // Fetch current user to get following list
            let userDoc = try await Firestore.firestore().collection("Users").document(currentUserUID).getDocument()
            let userData = try userDoc.data(as: User.self)
            
            // Include current user's UID in the list to show their own posts as well
            var uidsToFetch = userData.following
            uidsToFetch.append(currentUserUID)
            
            // Fetch posts from followed users
            let postsSnapshot = try await Firestore.firestore().collection("Posts")
                .whereField("userUID", in: uidsToFetch)
                .order(by: "publishedDate", descending: true)
                .getDocuments()
            
            self.followedPosts = postsSnapshot.documents.compactMap { try? $0.data(as: Post.self) }
        } catch {
            print("Error fetching followed posts: \(error)")
        }
        
        isLoading = false
    }
}
