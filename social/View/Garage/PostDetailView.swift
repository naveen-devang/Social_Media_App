//
//  PostDetailView.swift
//  social
//
//  Created by Naveen on 04/09/2024.
//

import SwiftUI
import SDWebImageSwiftUI


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
                
                if !post.imageURLs.isEmpty {
                    TabView {
                        ForEach(post.imageURLs, id: \.self) { imageURL in
                            WebImage(url: imageURL)
                                .resizable()
                                .scaledToFit()
                        }
                    }
                    .frame(height: 300)
                    .tabViewStyle(PageTabViewStyle())
                }
                
                if !post.hashtags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(post.hashtags, id: \.self) { hashtag in
                                Text(hashtag)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(15)
                            }
                        }
                    }
                }
                
                HStack {
                    Image(systemName: "heart")
                    Text("\(post.likes)")
                    
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
        let db = Firestore.firestore()
        db.collection("Vehicles").document(vehicleID).getDocument { (document, error) in
            if let document = document, document.exists {
                self.vehicle = try? document.data(as: Vehicle.self)
            } else {
                print("Vehicle document does not exist")
            }
        }
    }
}
