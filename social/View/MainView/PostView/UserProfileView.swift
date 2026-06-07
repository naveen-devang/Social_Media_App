//
//  UserProfileView.swift
//  social
//
//  Created by デバン・ナビーン on 12/04/24.
//

import SwiftUI


struct UserProfileView: View {
    let userID: String // Assuming you pass the user ID to fetch user data

    var body: some View {
        // Implement your user profile view here using the userID to fetch user data
        Text("User Profile for userID: \(userID)")
            .navigationBarTitle("User Profile")
    }
}

