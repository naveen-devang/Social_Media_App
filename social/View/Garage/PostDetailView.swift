//
//  PostDetailView.swift
//  social
//
//  Created by Naveen on 04/09/2024.
//

import SwiftUI
import SDWebImageSwiftUI
import Appwrite

struct PostDetailView: View {
    let post: Post
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    WebImage(url: post.userProfileURL)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                    
                    Text(post.userName)
                        .font(.headline)
                }
                
                Text(post.text)
                    .font(.body)
                
                if let imageURL = post.imageURL {
                    WebImage(url: imageURL)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                }
                
                HStack {
                    Image(systemName: "heart")
                    Text("\(post.likedIDs.count)")
                    
                    Spacer()
                    
                    Text(post.publishedDate, style: .date)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding()
        }
        .navigationTitle("Post Detail")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TaggedVehicleView: View {
    let vehicleID: String
    @State private var vehicle: Vehicle?
    
    var body: some View {
        Group {
            if let vehicle = vehicle {
                VehicleDetailView(vehicle: vehicle)
            } else {
                ProgressView()
            }
        }
        .onAppear {
            fetchVehicle()
        }
    }
    
    private func fetchVehicle() {
        Task {
            do {
                let doc = try await AppwriteManager.shared.databases.getDocument(
                    databaseId: AppwriteManager.shared.databaseId,
                    collectionId: "vehicles",
                    documentId: vehicleID,
                    nestedType: Vehicle.self
                )
                await MainActor.run {
                    self.vehicle = doc.data
                }
            } catch {
                print("Error fetching vehicle: \(error.localizedDescription)")
            }
        }
    }
}
