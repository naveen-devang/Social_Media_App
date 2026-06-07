//
//  UserTaggingView.swift
//  social
//
//  Created by デバン・ナビーン on 14/04/24.
//

import SwiftUI

struct UserTaggingView: View {
    @ObservedObject var userRepository: UserRepository
    @Binding var text: String
    var onSelectUser: (User) -> Void

    var body: some View {
        VStack {
            TextField("Type @ to tag users", text: $text)
                .onChange(of: text) { newText in
                    if newText.contains("@") {
                        let tagComponents = newText.split(separator: "@")
                        if let lastComponent = tagComponents.last, !lastComponent.isEmpty {
                            let filteredUsers = userRepository.users.filter { user in
                                user.username.lowercased().hasPrefix(lastComponent.lowercased())
                            }
                            updateSuggestions(filteredUsers)
                        }
                    }
                }
            
            List {
                ForEach(suggestedUsers, id: \.id) { user in
                    Button(action: {
                        onSelectUser(user) // Call the closure when user is selected
                    }) {
                        Text("@\(user.username)")
                    }
                }
            }
        }
    }
    
    @State private var suggestedUsers: [User] = []
    
    private func updateSuggestions(_ users: [User]) {
        suggestedUsers = users
    }
}
