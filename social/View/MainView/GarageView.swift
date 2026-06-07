//
//  GarageView.swift
//  social
//
//  Created by デバン・ナビーン on 20/03/24.
//

import SwiftUI
import Combine
import SDWebImageSwiftUI
import Appwrite

class GarageViewModel: ObservableObject {
    @Published var vehicles: [Vehicle] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var realtimeSubscription: RealtimeSubscription?
    @AppStorage("user_UID") private var currentUserUID: String = ""
    
    deinit {
        realtimeSubscription = nil
    }
    
    func fetchUserVehicles(for userUID: String?) {
        isLoading = true
        Task { try? await realtimeSubscription?.close() }
        
        let targetUID: String
        if let userUID = userUID {
            targetUID = userUID
        } else {
            guard !currentUserUID.isEmpty else {
                self.errorMessage = "User not logged in"
                self.isLoading = false
                return
            }
            targetUID = currentUserUID
        }
        
        Task {
            do {
                // Initial Fetch
                let result = try await AppwriteManager.shared.databases.listDocuments(
                    databaseId: AppwriteManager.shared.databaseId,
                    collectionId: "vehicles",
                    queries: [
                        Query.equal("ownerUID", value: targetUID),
                        Query.equal("isActive", value: true),
                        Query.limit(100)
                    ],
                    nestedType: Vehicle.self
                )
                
                await MainActor.run {
                    self.vehicles = result.documents.map { doc -> Vehicle in
                        var vehicle = doc.data
                        vehicle.id = doc.id
                        return vehicle
                    }.sorted(by: { $0.manufacturer < $1.manufacturer })
                    self.isLoading = false
                }
                
                // Realtime subscription
                let channel = "databases.\(AppwriteManager.shared.databaseId).collections.vehicles.documents"
                realtimeSubscription = try await AppwriteManager.shared.realtime.subscribe(channels: [channel]) { [weak self] response in
                    guard let self = self else { return }
                    
                    if (response.events ?? []).contains(where: { $0.contains(".delete") }) {
                        guard let payload = response.payload, let deletedId = payload["$id"] as? String else { return }
                        Task { @MainActor in
                            self.vehicles.removeAll { $0.id == deletedId }
                        }
                        return
                    }
                    
                    guard let payload = response.payload else { return }
                    
                    if let data = try? JSONSerialization.data(withJSONObject: payload, options: []),
                       var updatedVehicle = try? JSONDecoder().decode(Vehicle.self, from: data) {
                        
                        guard updatedVehicle.ownerUID == targetUID else { return }
                        updatedVehicle.id = payload["$id"] as? String
                        
                        Task { @MainActor in
                            if !updatedVehicle.isActive {
                                self.vehicles.removeAll { $0.id == updatedVehicle.id }
                            } else {
                                if let idx = self.vehicles.firstIndex(where: { $0.id == updatedVehicle.id }) {
                                    self.vehicles[idx] = updatedVehicle
                                } else {
                                    self.vehicles.append(updatedVehicle)
                                }
                            }
                            self.vehicles.sort(by: { $0.manufacturer < $1.manufacturer })
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "Error fetching vehicles: \(error.localizedDescription)"
                }
            }
        }
    }
}

struct GarageView: View {
    @StateObject private var viewModel = GarageViewModel()
    @State private var isAddingVehicle = false
    let userUID: String?
    let showAddButton: Bool
    
    @AppStorage("user_UID") private var currentUserUID: String = ""
    
    init(userUID: String? = nil, showAddButton: Bool = true) {
        self.userUID = userUID
        self.showAddButton = showAddButton
    }
    
    var body: some View {
        VStack {
            vehicleList
        }
        .overlay(
            showAddButton ? addVehicleButton : nil,
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
                    if currentUserUID == vehicle.ownerUID {
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

