//
//  ProfilePostsView.swift
//  social
//
//  Created by デバン・ナビーン on 13/03/24.
//

import SwiftUI


struct ProfilePostsView: View {
    @State private var userPosts: [Post] = []
    @State private var createNewPost = false
    
    var body: some View {
        VStack {
            // Display user's posts
            ReusablePostsView(posts: $userPosts, basedOnUID: true, uid: Auth.auth().currentUser?.uid ?? "", isProfileView: true)
            .task {
                    await fetchUserPosts()
                }
        }
        .overlay(
            Button(action: {
                createNewPost.toggle()
            }) {
                Image(systemName: "plus")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(13)
                    .background(.blue, in: Circle())
            }
            .padding(15)
            , alignment: .bottomTrailing // Align the overlay to the bottom trailing corner
        )
        .sheet(isPresented: $createNewPost) {
            // Present CreateNewPost view when isCreatingPost is true
            CreateNewPost { newPost in
                // Handle the new post, for example, append it to userPosts
                userPosts.append(newPost)
            }
        }
    }
    
    func fetchUserPosts() async {
        // Fetch user's posts as before
    }
}


#Preview {
    ProfilePostsView()
}
