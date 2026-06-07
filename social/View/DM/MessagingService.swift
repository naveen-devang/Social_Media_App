//
//  MessagingService.swift
//  social
//

import Foundation
import Combine
import Appwrite

class MessagingService: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var currentMessages: [Message] = []
    @Published var currentConversation: Conversation?
    
    private var conversationsSubscription: RealtimeSubscription?
    private var messagesSubscription: RealtimeSubscription?
    
    // Get all conversations for current user
    func fetchConversations(for userId: String) {
        // Unsubscribe from any existing listener
        Task { try? await conversationsSubscription?.close() }
        
        Task {
            do {
                // Initial fetch
                let result = try await AppwriteManager.shared.databases.listDocuments(
                    databaseId: AppwriteManager.shared.databaseId,
                    collectionId: "conversations",
                    queries: [
                        Query.contains("participants", value: [userId]),
                        Query.orderDesc("lastMessageTimestamp"),
                        Query.limit(100)
                    ],
                    nestedType: Conversation.self
                )
                
                await MainActor.run {
                    self.conversations = result.documents.map { doc -> Conversation in
                        var conv = doc.data
                        conv.id = doc.id
                        return conv
                    }
                }
                
                // Realtime subscription
                let channel = "databases.\(AppwriteManager.shared.databaseId).collections.conversations.documents"
                conversationsSubscription = try await AppwriteManager.shared.realtime.subscribe(channels: [channel]) { [weak self] response in
                    guard let self = self else { return }
                    
                    if (response.events ?? []).contains(where: { $0.contains(".delete") }) {
                        // If conversation deleted
                        guard let payload = response.payload, let deletedId = payload["$id"] as? String else { return }
                        Task { @MainActor in
                            self.conversations.removeAll { $0.id == deletedId }
                        }
                        return
                    }
                    
                    guard let payload = response.payload else { return }
                    
                    if let data = try? JSONSerialization.data(withJSONObject: payload, options: []),
                       var updatedConv = try? JSONDecoder().decode(Conversation.self, from: data) {
                        
                        guard updatedConv.participants.contains(userId) else { return }
                        updatedConv.id = payload["$id"] as? String
                        
                        Task { @MainActor in
                            if let idx = self.conversations.firstIndex(where: { $0.id == updatedConv.id }) {
                                self.conversations[idx] = updatedConv
                            } else {
                                self.conversations.append(updatedConv)
                            }
                            self.conversations.sort(by: { $0.lastMessageTimestamp > $1.lastMessageTimestamp })
                        }
                    }
                }
            } catch {
                print("Error fetching conversations: \(error.localizedDescription)")
            }
        }
    }
    
    // Get messages for a specific conversation
    func fetchMessages(for conversationId: String) {
        // Unsubscribe from any existing listener
        Task { try? await messagesSubscription?.close() }
        
        print("Fetching messages for conversation: \(conversationId)")
        
        Task {
            do {
                let result = try await AppwriteManager.shared.databases.listDocuments(
                    databaseId: AppwriteManager.shared.databaseId,
                    collectionId: "messages",
                    queries: [
                        Query.equal("conversationId", value: conversationId),
                        Query.orderAsc("timestamp"),
                        Query.limit(100)
                    ],
                    nestedType: Message.self
                )
                
                await MainActor.run {
                    self.currentMessages = result.documents.map { doc -> Message in
                        var msg = doc.data
                        msg.id = doc.id
                        return msg
                    }
                    print("Found \(self.currentMessages.count) messages")
                }
                
                // Realtime subscription for messages in this conversation
                let channel = "databases.\(AppwriteManager.shared.databaseId).collections.messages.documents"
                messagesSubscription = try await AppwriteManager.shared.realtime.subscribe(channels: [channel]) { [weak self] response in
                    guard let self = self else { return }
                    
                    if (response.events ?? []).contains(where: { $0.contains(".delete") }) {
                        guard let payload = response.payload, let deletedId = payload["$id"] as? String else { return }
                        Task { @MainActor in
                            self.currentMessages.removeAll { $0.id == deletedId }
                        }
                        return
                    }
                    
                    guard let payload = response.payload else { return }
                    
                    if let data = try? JSONSerialization.data(withJSONObject: payload, options: []),
                       var updatedMsg = try? JSONDecoder().decode(Message.self, from: data) {
                        
                        guard updatedMsg.conversationId == conversationId else { return }
                        updatedMsg.id = payload["$id"] as? String
                        
                        Task { @MainActor in
                            if let idx = self.currentMessages.firstIndex(where: { $0.id == updatedMsg.id }) {
                                self.currentMessages[idx] = updatedMsg
                            } else {
                                self.currentMessages.append(updatedMsg)
                            }
                            self.currentMessages.sort(by: { $0.timestamp < $1.timestamp })
                        }
                    }
                }
            } catch {
                print("Error fetching messages: \(error.localizedDescription)")
            }
        }
    }
    
    // Create a new conversation
    func createConversation(with userId: String, currentUserId: String, firstMessage: String, completion: @escaping (String?) -> Void) {
        let participants = [currentUserId, userId].sorted()
        
        Task {
            do {
                // Check if conversation already exists by querying conversations containing current user
                let result = try await AppwriteManager.shared.databases.listDocuments(
                    databaseId: AppwriteManager.shared.databaseId,
                    collectionId: "conversations",
                    queries: [
                        Query.contains("participants", value: [currentUserId]),
                        Query.limit(100)
                    ],
                    nestedType: Conversation.self
                )
                
                // Filter locally in Swift for exact matches
                if let existingDoc = result.documents.first(where: { $0.data.participants.sorted() == participants }) {
                    let convId = existingDoc.id
                    self.sendMessage(text: firstMessage, to: convId, senderId: currentUserId, receiverId: userId)
                    completion(convId)
                    return
                }
                
                // Otherwise create new conversation document
                let newConversation = Conversation(
                    id: nil,
                    participants: participants,
                    lastMessage: firstMessage,
                    lastMessageTimestamp: Date(),
                    lastMessageSenderId: currentUserId,
                    unreadCount: [userId: 1]
                )
                
                let docId = ID.unique()
                _ = try await AppwriteManager.shared.databases.createDocument(
                    databaseId: AppwriteManager.shared.databaseId,
                    collectionId: "conversations",
                    documentId: docId,
                    data: newConversation.toDictionary
                )
                
                // Add first message
                self.sendMessage(text: firstMessage, to: docId, senderId: currentUserId, receiverId: userId)
                completion(docId)
            } catch {
                print("Error creating conversation: \(error.localizedDescription)")
                completion(nil)
            }
        }
    }
    
    // Send a message in an existing conversation
    func sendMessage(text: String, to conversationId: String, senderId: String, receiverId: String) {
        Task {
            do {
                // Create and write message
                let message = Message(
                    id: nil,
                    conversationId: conversationId,
                    senderId: senderId,
                    receiverId: receiverId,
                    text: text,
                    timestamp: Date(),
                    isRead: false
                )
                
                _ = try await AppwriteManager.shared.databases.createDocument(
                    databaseId: AppwriteManager.shared.databaseId,
                    collectionId: "messages",
                    documentId: ID.unique(),
                    data: message.toDictionary
                )
                
                // Fetch and update the conversation
                let convDoc = try await AppwriteManager.shared.databases.getDocument(
                    databaseId: AppwriteManager.shared.databaseId,
                    collectionId: "conversations",
                    documentId: conversationId,
                    nestedType: Conversation.self
                )
                
                var conversation = convDoc.data
                conversation.lastMessage = text
                conversation.lastMessageTimestamp = Date()
                conversation.lastMessageSenderId = senderId
                conversation.unreadCount[receiverId] = (conversation.unreadCount[receiverId] ?? 0) + 1
                
                _ = try await AppwriteManager.shared.databases.updateDocument(
                    databaseId: AppwriteManager.shared.databaseId,
                    collectionId: "conversations",
                    documentId: conversationId,
                    data: conversation.toDictionary
                )
            } catch {
                print("Error sending message: \(error.localizedDescription)")
            }
        }
    }
    
    // Mark messages as read
    func markAsRead(conversationId: String, userId: String) {
        Task {
            do {
                // Get all unread messages received by this user in this conversation
                let result = try await AppwriteManager.shared.databases.listDocuments(
                    databaseId: AppwriteManager.shared.databaseId,
                    collectionId: "messages",
                    queries: [
                        Query.equal("conversationId", value: conversationId),
                        Query.equal("receiverId", value: userId),
                        Query.equal("isRead", value: false)
                    ],
                    nestedType: Message.self
                )
                
                // Update each message as read
                for doc in result.documents {
                    _ = try await AppwriteManager.shared.databases.updateDocument(
                        databaseId: AppwriteManager.shared.databaseId,
                        collectionId: "messages",
                        documentId: doc.id,
                        data: ["isRead": true]
                    )
                }
                
                // Reset unread count for this user in the conversation
                let convDoc = try await AppwriteManager.shared.databases.getDocument(
                    databaseId: AppwriteManager.shared.databaseId,
                    collectionId: "conversations",
                    documentId: conversationId,
                    nestedType: Conversation.self
                )
                
                var conversation = convDoc.data
                conversation.unreadCount[userId] = 0
                
                _ = try await AppwriteManager.shared.databases.updateDocument(
                    databaseId: AppwriteManager.shared.databaseId,
                    collectionId: "conversations",
                    documentId: conversationId,
                    data: conversation.toDictionary
                )
            } catch {
                print("Error marking messages as read: \(error.localizedDescription)")
            }
        }
    }
    
    // Delete a conversation
    func deleteConversation(conversationId: String, completion: @escaping (Bool) -> Void) {
        Task {
            do {
                // Fetch all messages in conversation
                let result = try await AppwriteManager.shared.databases.listDocuments(
                    databaseId: AppwriteManager.shared.databaseId,
                    collectionId: "messages",
                    queries: [
                        Query.equal("conversationId", value: conversationId),
                        Query.limit(500)
                    ]
                )
                
                // Delete messages
                for doc in result.documents {
                    _ = try await AppwriteManager.shared.databases.deleteDocument(
                        databaseId: AppwriteManager.shared.databaseId,
                        collectionId: "messages",
                        documentId: doc.id
                    )
                }
                
                // Delete conversation document
                _ = try await AppwriteManager.shared.databases.deleteDocument(
                    databaseId: AppwriteManager.shared.databaseId,
                    collectionId: "conversations",
                    documentId: conversationId
                )
                
                completion(true)
            } catch {
                print("Error deleting conversation: \(error.localizedDescription)")
                completion(false)
            }
        }
    }
    
    deinit {
        conversationsSubscription = nil
        messagesSubscription = nil
    }
}
