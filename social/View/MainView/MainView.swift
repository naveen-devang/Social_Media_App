//
//  MainView.swift
//  social
//
//  Created by デバン・ナビーン on 22/06/23.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        //MARK: TabView With Recent Post's and Profile Tabs
        TabView{
            PostsView()
                .tabItem{
                    Image(systemName: "rectangle.portrait.on.rectangle.portrait.angled")
                        Text("Post's")
                }
            
            ProfileView()
                .tabItem{
                    Image(systemName: "gear")
                        Text("Profile")
                }
        }
        //Changing Tab Label Tint to Blue
        .tint(.blue)
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
