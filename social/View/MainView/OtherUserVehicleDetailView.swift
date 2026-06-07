//
//  OtherUserVehicleDetailView.swift
//  social
//
//  Created by デバン・ナビーン on 22/03/24.
//


import SwiftUI
import SDWebImageSwiftUI



struct OtherUserVehicleDetailView: View {
    let vehicle: Vehicle
    let isOtherUser: Bool
    @StateObject private var viewModel: VehicleDetailViewModel
    
    init(vehicle: Vehicle, isOtherUser: Bool = false) {
        self.vehicle = vehicle
        self.isOtherUser = isOtherUser
        self._viewModel = StateObject(wrappedValue: VehicleDetailViewModel(vehicle: vehicle))
    }
    
    private var editHistoryButton: some View {
        NavigationLink(destination: EditHistoryView(vehicleID: vehicle.id ?? "")) {
            Image(systemName: "clock.arrow.circlepath")
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("\(NumberFormatter.localizedString(from: NSNumber(value: vehicle.year), number: .none)) \(vehicle.manufacturer) \(vehicle.model)")
                    .font(.custom("Inter-Bold", size: 20))
                
                if let imageUrls = vehicle.imageUrls, !imageUrls.isEmpty {
                    ImageCarousel(imageUrls: imageUrls)
                }
                
                VehicleDetailTable(vehicle: vehicle)
                
                Text("Tagged Posts")
                    .font(.custom("Inter-Bold", size: 18))
                    .padding(.top)
                
                TaggedPostsGridView(posts: viewModel.taggedPosts)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Vehicle Detail")
        .overlay(
            Divider()
                .background(Color.gray)
                .frame(height: 1),
            alignment: .bottom
        )
        .navigationBarItems(trailing: editHistoryButton)
        .onAppear {
            viewModel.fetchTaggedPosts()
        }
    }
}
