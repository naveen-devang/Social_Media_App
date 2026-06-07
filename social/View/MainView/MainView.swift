//
//  MainView.swift
//  social
//
//  Created by デバン・ナビーン on 22/06/23.
//

import SwiftUI


struct MainView: View {
    @State private var carListings: [CarListing] = []
    @StateObject private var userSession = UserSession()
    
    @StateObject private var messagingService = MessagingService()
    @StateObject private var userViewModel = UserViewModel()
    
    var body: some View {
        TabView {
            PostsView()
                .tabItem {
                    Image(systemName: "rectangle.portrait.on.rectangle.portrait.angled")
                    Text("Feed")
                }
            
            ProfileView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Profile")
                }
            
            NewsView()
                .tabItem {
                    Image(systemName: "newspaper")
                    Text("News")
                }
            
            ConversationsView()
                .tabItem {
                    Image(systemName: "message.fill")
                    Text("Messages")
                }

//            CommunityListView()
//                .tabItem {
//                    Image(systemName: "car.side")
//                    Text("Community")
//                }
//            CommunityListView()
//                .tabItem {
//                    Image(systemName: "person.3.fill")
//                    Text("Community")
//                }
            
            CarListingsView(carListings: $carListings)
                .navigationTitle("Vehicle Listings")
                .tabItem {
                    Image(systemName: "list.bullet.below.rectangle")
                    Text("Vehicle Listings")
                }

        }
        .environmentObject(messagingService)
        .environmentObject(userViewModel)
        .tint(.blue)
    }
}



struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}

