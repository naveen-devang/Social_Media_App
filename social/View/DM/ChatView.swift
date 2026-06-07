//
//  ChatView.swift
//  social
//
//  Created by Naveen Devang on 3/13/25.
//

import SwiftUI


struct ChatView: View {
    @EnvironmentObject var messagingService: MessagingService
    @EnvironmentObject var userViewModel: UserViewModel
    
    var conversation: Conversation?
    var conversationId: String?
    
    @State private var messageText = ""
    @State private var scrollToBottom = false
    @State private var recipientUser: User?
    
    private var currentConversationId: String? {
        conversation?.id ?? conversationId
    }
    
    var body: some View {
        VStack {
            // Messages scroll view
            ScrollViewReader { scrollView in
                ScrollView {
                    LazyVStack {
                        ForEach(messagingService.currentMessages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                    }
                    .padding(.horizontal)
                }
                .onChange(of: messagingService.currentMessages.count) { _ in
                    withAnimation {
                        if let lastMessage = messagingService.currentMessages.last {
                            scrollView.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
                .onAppear {
                    if let lastMessage = messagingService.currentMessages.last {
                        scrollView.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
            
            // Message input
            HStack {
                TextField("Message", text: $messageText)
                    .padding(10)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(20)
                
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .blue)
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
        }
        .navigationTitle(recipientUser?.username ?? "Chat")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            setupChat()
        }
        .onDisappear {
            // Mark messages as read when leaving the chat
            if let currentUser = userViewModel.currentUser,
               let conversationId = currentConversationId {
                messagingService.markAsRead(conversationId: conversationId, userId: currentUser.userUID)
            }
        }
    }
    
    private func setupChat() {
        guard let currentUser = userViewModel.currentUser else {
            print("Current user is nil")
            return
        }
        
        // If we have a conversation object
        if let conversation = conversation {
            print("Setting up chat with conversation: \(conversation.id ?? "unknown")")
            
            if let id = conversation.id {
                messagingService.fetchMessages(for: id)
                
                // Mark messages as read
                messagingService.markAsRead(conversationId: id, userId: currentUser.userUID)
                
                // Find recipient user
                if let otherParticipantId = conversation.participants.first(where: { $0 != currentUser.userUID }) {
                    recipientUser = userViewModel.users.first(where: { $0.userUID == otherParticipantId })
                    print("Found recipient: \(recipientUser?.username ?? "unknown")")
                }
            }
        }
        // If we only have a conversation ID
        else if let conversationId = conversationId {
            print("Setting up chat with conversationId: \(conversationId)")
            messagingService.fetchMessages(for: conversationId)
            
            // Get the conversation object to find recipient
            if let foundConversation = messagingService.conversations.first(where: { $0.id == conversationId }) {
                if let otherParticipantId = foundConversation.participants.first(where: { $0 != currentUser.userUID }) {
                    recipientUser = userViewModel.users.first(where: { $0.userUID == otherParticipantId })
                    print("Found recipient: \(recipientUser?.username ?? "unknown")")
                }
            }
        }
    }
    
    private func sendMessage() {
        guard let currentUser = userViewModel.currentUser,
              let conversationId = currentConversationId,
              let recipientUser = recipientUser,
              !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        messagingService.sendMessage(
            text: messageText,
            to: conversationId,
            senderId: currentUser.userUID,
            receiverId: recipientUser.userUID
        )
        
        messageText = ""
    }
}

struct MessageBubble: View {
    @EnvironmentObject var userViewModel: UserViewModel
    let message: Message
    
    private var isFromCurrentUser: Bool {
        guard let currentUser = userViewModel.currentUser else { return false }
        return message.senderId == currentUser.userUID
    }
    
    var body: some View {
        HStack {
            if isFromCurrentUser {
                Spacer()
                
                // Message content
                Text(message.text)
                    .padding(12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(
                        // Read indicator
                        HStack {
                            Spacer()
                            if message.isRead {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 8))
                                    .foregroundColor(.white)
                                    .padding(.trailing, 4)
                                    .padding(.bottom, 4)
                            }
                        },
                        alignment: .bottomTrailing
                    )
            } else {
                // Profile image for other user
                if let senderUser = userViewModel.users.first(where: { $0.userUID == message.senderId }) {
                    if let profileURL = senderUser.userProfileURL {
                        AsyncImage(url: profileURL) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Image(systemName: "person.crop.circle")
                                .resizable()
                        }
                        .frame(width: 30, height: 30)
                        .clipShape(Circle())
                    } else {
                        Image(systemName: "person.crop.circle")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.gray)
                    }
                }
                
                // Message content
                Text(message.text)
                    .padding(12)
                    .background(Color(UIColor.systemGray5))
                    .foregroundColor(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                
                Spacer()
            }
        }
        .padding(.vertical, 4)
        // Timestamp tooltip on press
        .overlay(
            HStack {
                Spacer()
                Text(formatDate(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .padding(.trailing, 4)
            }
            .padding(.top, -15),
            alignment: .top
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
