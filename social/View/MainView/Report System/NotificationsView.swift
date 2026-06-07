//
//  NotificationsView.swift
//  social
//

import SwiftUI
import Appwrite

class NotificationsViewModel: ObservableObject {
    @Published var notifications: [AppNotification] = []
    private var subscription: RealtimeSubscription?
    
    func startListening(for userUID: String) {
        subscription?.unsubscribe()
        
        Task {
            do {
                let result = try await AppwriteManager.shared.databases.listDocuments(
                    databaseId: AppwriteManager.shared.databaseId,
                    collectionId: "notifications",
                    queries: [
                        Query.equal("userUID", value: userUID),
                        Query.orderDesc("timestamp"),
                        Query.limit(100)
                    ],
                    nestedType: AppNotification.self
                )
                
                await MainActor.run {
                    self.notifications = result.documents.map { doc -> AppNotification in
                        var notif = doc.data
                        notif.id = doc.id
                        return notif
                    }
                }
                
                // Realtime subscription for notification collection updates
                let channel = "databases.\(AppwriteManager.shared.databaseId).collections.notifications.documents"
                subscription = AppwriteManager.shared.realtime.subscribe(channels: [channel]) { [weak self] response in
                    guard let self = self else { return }
                    
                    if response.events.contains(where: { $0.contains(".delete") }) {
                        guard let payload = response.payload, let deletedId = payload["$id"] as? String else { return }
                        Task { @MainActor in
                            self.notifications.removeAll { $0.id == deletedId }
                        }
                        return
                    }
                    
                    guard let payload = response.payload else { return }
                    if let data = try? JSONSerialization.data(withJSONObject: payload, options: []),
                       var updatedNotif = try? JSONDecoder().decode(AppNotification.self, from: data) {
                        
                        guard updatedNotif.userUID == userUID else { return }
                        updatedNotif.id = payload["$id"] as? String
                        
                        Task { @MainActor in
                            if let idx = self.notifications.firstIndex(where: { $0.id == updatedNotif.id }) {
                                self.notifications[idx] = updatedNotif
                            } else {
                                self.notifications.append(updatedNotif)
                            }
                            self.notifications.sort(by: { $0.timestamp > $1.timestamp })
                        }
                    }
                }
            } catch {
                print("Error fetching notifications: \(error.localizedDescription)")
            }
        }
    }
    
    func markAsRead(_ notificationID: String, userUID: String) {
        Task {
            do {
                _ = try await AppwriteManager.shared.databases.updateDocument(
                    databaseId: AppwriteManager.shared.databaseId,
                    collectionId: "notifications",
                    documentId: notificationID,
                    data: ["read": true]
                )
            } catch {
                print("Error marking notification as read: \(error.localizedDescription)")
            }
        }
    }
    
    deinit {
        subscription?.unsubscribe()
    }
}

struct NotificationsView: View {
    @StateObject private var viewModel = NotificationsViewModel()
    let userUID: String  // Changed from userID to userUID to match User model
    
    var body: some View {
        List(viewModel.notifications) { notification in
            VStack(alignment: .leading, spacing: 8) {
                Text(notification.title)
                    .font(.headline)
                Text(notification.message)
                    .font(.body)
                Text(notification.timestamp.formatted())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
            .opacity(notification.read ? 0.6 : 1.0)
            .onAppear {
                if !notification.read {
                    if let notificationID = notification.id {
                        viewModel.markAsRead(notificationID, userUID: userUID)
                    }
                }
            }
        }
        .onAppear {
            viewModel.startListening(for: userUID)
        }
    }
}
