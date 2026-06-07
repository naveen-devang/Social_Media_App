//
//  ReuseableProfileContent.swift
//  social
//
//  Created by デバン・ナビーン on 22/06/23.
//

import SwiftUI

import SDWebImageSwiftUI

struct ReuseableProfileContent: View {
    @State private var selectedTab: Tab = .posts
    @State private var fetchedPosts: [Post] = []
    
    enum Tab {
        case posts, garage
    }
    
    let user: User
    
    var body: some View {
        NavigationView{
            VStack(spacing: 0) {
                ScrollView {
                    VStack {
                        profileHeader
                        tabSwitcher
                    }
                }
                .frame(height: 200) // Adjust this value as needed
                
                selectedTabContent
            }
        }
    }
    
    private var profileHeader: some View {
        ReusableProfileContent(user: user)
    }
    
    private var tabSwitcher: some View {
        HStack {
            TabButton(title: "Posts", tab: .posts, isSelected: selectedTab == .posts) {
                selectedTab = .posts
                fetchedPosts = []
            }
            TabButton(title: "Garage", tab: .garage, isSelected: selectedTab == .garage) {
                selectedTab = .garage
            }
        }
    }
    
    @ViewBuilder
    private var selectedTabContent: some View {
        if selectedTab == .posts {
            ReusablePostsView(posts: $fetchedPosts, basedOnUID: true, uid: user.userUID, isProfileView: true)
        } else {
            UserGarageView(userUID: user.userUID)
        }
    }
}
