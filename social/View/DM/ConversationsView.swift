//
//  ConversationsView.swift
//  social
//
//  Created by Naveen Devang on 3/13/25.
//

import SwiftUI


struct ConversationsView: View {
    @EnvironmentObject var messagingService: MessagingService
    @EnvironmentObject var userViewModel: UserViewModel
    @State private var searchText = ""
    @State private var showNewMessageSheet = false
    
    var filteredConversations: [Conversation] {
        if searchText.isEmpty {
            return messagingService.conversations
        } else {
            return messagingService.conversations.filter { conversation in
                // Find the other participant's user object
                if let otherParticipantId = conversation.participants.first(where: { $0 != userViewModel.currentUser?.userUID }) {
                    if let otherUser = userViewModel.users.first(where: { $0.userUID == otherParticipantId }) {
                        return otherUser.username.lowercased().contains(searchText.lowercased())
                    }
                }
                return false
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            if #available(iOS 17.0, *) {
                List {
                    ForEach(filteredConversations) { conversation in
                        NavigationLink(destination: ChatView(conversation: conversation)) {
                            ConversationRow(conversation: conversation)
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let conversation = filteredConversations[index]
                            if let id = conversation.id {
                                messagingService.deleteConversation(conversationId: id) { _ in
                                    // Handle completion if needed
                                }
                            }
                        }
                    }
                }
                
                .searchable(text: $searchText, prompt: "Search conversations")
                .onAppear {
                    if let currentUser = userViewModel.currentUser {
                        messagingService.fetchConversations(for: currentUser.userUID)
                    }
                }
                .sheet(isPresented: $showNewMessageSheet) {
                    NewMessageView()
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showNewMessageSheet = true
                        }) {
                            Image(systemName: "square.and.pencil")
                        }
                    }
                }
                .navigationTitle("Messages")
                .toolbarTitleDisplayMode(.inlineLarge)
            } else {
                // Fallback on earlier versions
                List {
                    ForEach(filteredConversations) { conversation in
                        NavigationLink(destination: ChatView(conversation: conversation)) {
                            ConversationRow(conversation: conversation)
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let conversation = filteredConversations[index]
                            if let id = conversation.id {
                                messagingService.deleteConversation(conversationId: id) { _ in
                                    // Handle completion if needed
                                }
                            }
                        }
                    }
                }
                
                .searchable(text: $searchText, prompt: "Search conversations")
                .onAppear {
                    if let currentUser = userViewModel.currentUser {
                        messagingService.fetchConversations(for: currentUser.userUID)
                    }
                }
                .sheet(isPresented: $showNewMessageSheet) {
                    NewMessageView()
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showNewMessageSheet = true
                        }) {
                            Image(systemName: "square.and.pencil")
                        }
                    }
                }
                .navigationTitle("Messages")
            }
        }
    }
}

struct ConversationRow: View {
    let conversation: Conversation
    
    @EnvironmentObject var userViewModel: UserViewModel
    
    var body: some View {
        if let currentUser = userViewModel.currentUser,
           let otherParticipantId = conversation.participants.first(where: { $0 != currentUser.userUID }),
           let otherUser = userViewModel.users.first(where: { $0.userUID == otherParticipantId }) {
            
            HStack {
                // Profile image
                if let profileURL = otherUser.userProfileURL {
                    AsyncImage(url: profileURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "person.crop.circle")
                            .resizable()
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.crop.circle")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.gray)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(otherUser.username)
                            .font(.headline)
                        
                        Spacer()
                        
                        // Time since last message
                        Text(timeAgo(from: conversation.lastMessageTimestamp))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        // Last message
                        Text(conversation.lastMessageSenderId == currentUser.userUID ? "You: \(conversation.lastMessage)" : conversation.lastMessage)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        // Unread indicator
                        if let unreadCount = conversation.unreadCount[currentUser.userUID], unreadCount > 0 {
                            Text("\(unreadCount)")
                                .font(.caption)
                                .foregroundColor(.white)
                                .frame(width: 24, height: 24)
                                .background(Color.blue)
                                .clipShape(Circle())
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        } else {
            Text("Loading conversation...")
        }
    }
    
    // Function to format timestamps as relative time
    func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
