//
//  NewMessageView.swift
//  social
//
//  Created by Naveen Devang on 3/13/25.
//

import SwiftUI

struct NewMessageView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userViewModel: UserViewModel
    @EnvironmentObject var messagingService: MessagingService
    
    @State private var searchText = ""
    @State private var selectedUser: User?
    @State private var messageText = ""
    @State private var showChat = false
    @State private var conversationId: String?
    
    var filteredUsers: [User] {
        if searchText.isEmpty {
            return userViewModel.users.filter { user in
                guard let currentUser = userViewModel.currentUser else { return false }
                return user.id != currentUser.id && !(currentUser.blockedUsers?.contains(user.userUID) ?? false)
            }
        } else {
            return userViewModel.users.filter { user in
                guard let currentUser = userViewModel.currentUser else { return false }
                return user.id != currentUser.id &&
                       !(currentUser.blockedUsers?.contains(user.userUID) ?? false) &&
                       user.username.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if let selectedUser = selectedUser {
                    // Compose message view
                    VStack {
                        HStack {
                            if let profileURL = selectedUser.userProfileURL {
                                AsyncImage(url: profileURL) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Image(systemName: "person.crop.circle")
                                        .resizable()
                                }
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                            } else {
                                Image(systemName: "person.crop.circle")
                                    .resizable()
                                    .frame(width: 40, height: 40)
                                    .foregroundColor(.gray)
                            }
                            
                            Text("Message to \(selectedUser.username)")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button(action: {
                                self.selectedUser = nil
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        
                        Divider()
                        
                        TextEditor(text: $messageText)
                            .frame(minHeight: 100)
                            .padding()
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(8)
                            .padding()
                        
                        Button(action: {
                            sendMessage()
                        }) {
                            Text("Send Message")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.blue)
                                .cornerRadius(8)
                                .padding(.horizontal)
                        }
                        .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .padding(.bottom)
                    }
                } else {
                    // User selection list
                    List(filteredUsers) { user in
                        Button(action: {
                            selectedUser = user
                        }) {
                            HStack {
                                if let profileURL = user.userProfileURL {
                                    AsyncImage(url: profileURL) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Image(systemName: "person.crop.circle")
                                            .resizable()
                                    }
                                    .frame(width: 40, height: 40)
                                    .clipShape(Circle())
                                } else {
                                    Image(systemName: "person.crop.circle")
                                        .resizable()
                                        .frame(width: 40, height: 40)
                                        .foregroundColor(.gray)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(user.username)
                                        .font(.headline)
                                    
                                    Text(user.userBio)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                        .lineLimit(1)
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .searchable(text: $searchText, prompt: "Search users")
                }
            }
            .navigationTitle("New Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .navigationDestination(isPresented: $showChat) {
                if let conversationId = conversationId {
                    ChatView(conversationId: conversationId)
                }
            }
        }
    }
    
    private func sendMessage() {
        guard let currentUser = userViewModel.currentUser,
              let selectedUser = selectedUser,
              !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        messagingService.createConversation(
            with: selectedUser.userUID,
            currentUserId: currentUser.userUID,
            firstMessage: messageText
        ) { conversationId in
            if let conversationId = conversationId {
                self.conversationId = conversationId
                self.showChat = true
                self.dismiss()
            }
        }
    }
}
