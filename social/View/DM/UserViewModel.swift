//
//  UserViewModel.swift
//  social
//

import SwiftUI
import Appwrite

class UserViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var usersSubscription: RealtimeSubscription?
    private var currentUserSubscription: RealtimeSubscription?
    
    init() {
        fetchUsers()
        setupCurrentUserListener()
    }
    
    private func setupCurrentUserListener() {
        Task {
            do {
                let accountUser = try await AppwriteManager.shared.account.get()
                self.fetchCurrentUser(uid: accountUser.id)
            } catch {
                await MainActor.run {
                    self.currentUser = nil
                }
            }
        }
    }
    
    func fetchCurrentUser(uid: String) {
        isLoading = true
        currentUserSubscription?.unsubscribe()
        
        Task {
            do {
                let doc = try await AppwriteManager.shared.databases.getDocument(
                    databaseId: AppwriteManager.shared.databaseId,
                    collectionId: AppwriteManager.shared.usersCollectionId,
                    documentId: uid,
                    nestedType: User.self
                )
                
                await MainActor.run {
                    self.isLoading = false
                    self.currentUser = doc.data
                    self.currentUser?.id = doc.id
                }
                
                // Realtime subscription for current user document updates
                let channel = "databases.\(AppwriteManager.shared.databaseId).collections.\(AppwriteManager.shared.usersCollectionId).documents.\(uid)"
                currentUserSubscription = AppwriteManager.shared.realtime.subscribe(channels: [channel]) { [weak self] response in
                    guard let self = self else { return }
                    guard let payload = response.payload else { return }
                    
                    if let data = try? JSONSerialization.data(withJSONObject: payload, options: []),
                       var updatedUser = try? JSONDecoder().decode(User.self, from: data) {
                        updatedUser.id = payload["$id"] as? String
                        
                        Task { @MainActor in
                            self.currentUser = updatedUser
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "Error fetching user: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func fetchUsers() {
        isLoading = true
        usersSubscription?.unsubscribe()
        
        Task {
            do {
                let result = try await AppwriteManager.shared.databases.listDocuments(
                    databaseId: AppwriteManager.shared.databaseId,
                    collectionId: AppwriteManager.shared.usersCollectionId,
                    queries: [Query.limit(100)],
                    nestedType: User.self
                )
                
                await MainActor.run {
                    self.isLoading = false
                    self.users = result.documents.map { doc -> User in
                        var u = doc.data
                        u.id = doc.id
                        return u
                    }
                }
                
                // Realtime subscription for collection updates
                let channel = "databases.\(AppwriteManager.shared.databaseId).collections.\(AppwriteManager.shared.usersCollectionId).documents"
                usersSubscription = AppwriteManager.shared.realtime.subscribe(channels: [channel]) { [weak self] response in
                    guard let self = self else { return }
                    
                    if response.events.contains(where: { $0.contains(".delete") }) {
                        guard let payload = response.payload, let deletedId = payload["$id"] as? String else { return }
                        Task { @MainActor in
                            self.users.removeAll { $0.id == deletedId }
                        }
                        return
                    }
                    
                    guard let payload = response.payload else { return }
                    if let data = try? JSONSerialization.data(withJSONObject: payload, options: []),
                       var updatedUser = try? JSONDecoder().decode(User.self, from: data) {
                        updatedUser.id = payload["$id"] as? String
                        
                        Task { @MainActor in
                            if let idx = self.users.firstIndex(where: { $0.id == updatedUser.id }) {
                                self.users[idx] = updatedUser
                            } else {
                                self.users.append(updatedUser)
                            }
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "Error fetching users: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func updateUserProfile(
        username: String? = nil,
        bio: String? = nil,
        bioLink: String? = nil,
        profileImage: UIImage? = nil,
        completion: @escaping (Bool) -> Void
    ) {
        guard let currentUser = currentUser, let userId = currentUser.id else {
            completion(false)
            return
        }
        
        var updateData: [String: Any] = [:]
        
        if let username = username {
            updateData["username"] = username
        }
        
        if let bio = bio {
            updateData["userBio"] = bio
        }
        
        if let bioLink = bioLink {
            updateData["userBioLink"] = bioLink
        }
        
        Task {
            do {
                _ = try await AppwriteManager.shared.databases.updateDocument(
                    databaseId: AppwriteManager.shared.databaseId,
                    collectionId: AppwriteManager.shared.usersCollectionId,
                    documentId: userId,
                    data: updateData
                )
                completion(true)
            } catch {
                await MainActor.run {
                    self.errorMessage = "Error updating profile: \(error.localizedDescription)"
                }
                completion(false)
            }
        }
    }
    
    // Check if a user is blocked by the current user
    func isUserBlocked(_ userId: String) -> Bool {
        guard let currentUser = currentUser else { return false }
        return currentUser.blockedUsers?.contains(userId) ?? false
    }
    
    // Block a user
    func blockUser(_ userId: String, completion: @escaping (Bool) -> Void) {
        guard let currentUser = currentUser, let currentUserId = currentUser.id else {
            completion(false)
            return
        }
        
        var blockedUsers = currentUser.blockedUsers ?? []
        
        if !blockedUsers.contains(userId) {
            blockedUsers.append(userId)
            
            Task {
                do {
                    _ = try await AppwriteManager.shared.databases.updateDocument(
                        databaseId: AppwriteManager.shared.databaseId,
                        collectionId: AppwriteManager.shared.usersCollectionId,
                        documentId: currentUserId,
                        data: [
                            "blockedUsers": blockedUsers
                        ]
                    )
                    completion(true)
                } catch {
                    print("Error blocking user: \(error.localizedDescription)")
                    completion(false)
                }
            }
        } else {
            completion(true) // User already blocked
        }
    }
    
    // Unblock a user
    func unblockUser(_ userId: String, completion: @escaping (Bool) -> Void) {
        guard let currentUser = currentUser, let currentUserId = currentUser.id else {
            completion(false)
            return
        }
        
        var blockedUsers = currentUser.blockedUsers ?? []
        
        if let index = blockedUsers.firstIndex(of: userId) {
            blockedUsers.remove(at: index)
            
            Task {
                do {
                    _ = try await AppwriteManager.shared.databases.updateDocument(
                        databaseId: AppwriteManager.shared.databaseId,
                        collectionId: AppwriteManager.shared.usersCollectionId,
                        documentId: currentUserId,
                        data: [
                            "blockedUsers": blockedUsers
                        ]
                    )
                    completion(true)
                } catch {
                    print("Error unblocking user: \(error.localizedDescription)")
                    completion(false)
                }
            }
        } else {
            completion(true) // User wasn't blocked
        }
    }
    
    // Clean up when done
    deinit {
        usersSubscription?.unsubscribe()
        currentUserSubscription?.unsubscribe()
    }
}
