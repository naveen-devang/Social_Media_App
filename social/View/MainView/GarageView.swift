//
//  GarageView.swift
//  social
//
//  Created by デバン・ナビーン on 20/03/24.
//

import SwiftUI

import Combine
import SDWebImageSwiftUI

class GarageViewModel: ObservableObject {
    @Published var vehicles: [Vehicle] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var listenerRegistration: ListenerRegistration?
    private let db = Firestore.firestore()
    
    deinit {
        listenerRegistration?.remove()
    }
    
    func fetchUserVehicles(for userUID: String?) {
        isLoading = true
        
        listenerRegistration?.remove()
        
        let query: Query
        if let userUID = userUID {
            query = db.collection("Vehicles")
                .whereField("ownerUID", isEqualTo: userUID)
                .whereField("isActive", isEqualTo: true)
        } else {
            guard let currentUserUID = Auth.auth().currentUser?.uid else {
                self.errorMessage = "User not logged in"
                self.isLoading = false
                return
            }
            query = db.collection("Vehicles")
                .whereField("ownerUID", isEqualTo: currentUserUID)
                .whereField("isActive", isEqualTo: true)
        }
        
        listenerRegistration = query.addSnapshotListener { [weak self] querySnapshot, error in
            guard let self = self else { return }
            
            self.isLoading = false
            
            if let error = error {
                self.errorMessage = "Error fetching vehicles: \(error.localizedDescription)"
                return
            }
            
            guard let documents = querySnapshot?.documents else {
                self.errorMessage = "No documents found"
                return
            }
            
            self.vehicles = documents.compactMap { document -> Vehicle? in
                try? document.data(as: Vehicle.self)
            }.sorted(by: { $0.manufacturer < $1.manufacturer })
        }
    }
}

struct GarageView: View {
    @StateObject private var viewModel = GarageViewModel()
    @State private var isAddingVehicle = false
    let userUID: String?
    let showAddButton: Bool
    
    init(userUID: String? = nil, showAddButton: Bool = true) {
        self.userUID = userUID
        self.showAddButton = showAddButton
    }
    
    var body: some View {
        VStack {
            vehicleList
        }
        .overlay(
            showAddButton ? addVehicleButton : nil, // Only show the add button if showAddButton is true
            alignment: .bottomTrailing
        )
        .sheet(isPresented: $isAddingVehicle) {
            AddVehicleView(isPresented: $isAddingVehicle)
        }
        .alert(item: Binding<AlertItem?>(
            get: { viewModel.errorMessage.map { AlertItem(message: $0) } },
            set: { _ in viewModel.errorMessage = nil }
        )) { alertItem in
            Alert(title: Text("Error"), message: Text(alertItem.message))
        }
        .onAppear {
            viewModel.fetchUserVehicles(for: userUID)
        }
    }
    
    private var vehicleList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(viewModel.vehicles) { vehicle in
                    if let currentUserUID = Auth.auth().currentUser?.uid, currentUserUID == vehicle.ownerUID {
                        NavigationLink(destination: VehicleDetailView(vehicle: vehicle)) {
                            VehicleRowView(vehicle: vehicle)
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        NavigationLink(destination: OtherUserVehicleDetailView(vehicle: vehicle, isOtherUser: true)) {
                            VehicleRowView(vehicle: vehicle)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var addVehicleButton: some View {
        Button(action: {
            isAddingVehicle = true
        }) {
            Image(systemName: "plus")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(Color.blue)
                .clipShape(Circle())
                .shadow(radius: 5)
        }
        .padding()
    }
}

struct VehicleRowView: View {
    let vehicle: Vehicle
    
    var body: some View {
        HStack(spacing: 10) {
            vehicleImage
            vehicleInfo
        }
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
    }
    
    private var vehicleImage: some View {
        Group {
            if let imageUrl = vehicle.imageUrls?.first, let url = URL(string: imageUrl) {
                WebImage(url: url)
                    .resizable()
                    .placeholder {
                        ProgressView()
                    }
                    .indicator(.activity)
                    .transition(.fade(duration: 0.5))
            } else {
                Image(systemName: "car").resizable()
            }
        }
        .aspectRatio(contentMode: .fill)
        .frame(width: 80, height: 80)
        .cornerRadius(10)
        .accessibility(label: Text("Vehicle image"))
    }
    
    private var vehicleInfo: some View {
        // This part remains unchanged
        VStack(alignment: .leading, spacing: 4) {
            Text("\(NumberFormatter.localizedString(from: NSNumber(value: vehicle.year), number: .none)) \(vehicle.manufacturer) \(vehicle.model)")
                .font(.headline)
            Text("VIN: \(vehicle.vinNumber.isEmpty ? "N/A" : vehicle.vinNumber)")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
}

struct AlertItem: Identifiable {
    let id = UUID()
    let message: String
}
