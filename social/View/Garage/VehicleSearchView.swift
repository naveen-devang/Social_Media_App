//
//  VehicleSearchView.swift
//  social
//
//  Created by Naveen on 15/08/2024.
//

import SwiftUI
import SDWebImageSwiftUI
import Appwrite

struct VehicleSearchView: View {
    @Binding var searchText: String
    @Binding var selectedVehicles: [Vehicle]
    @StateObject private var viewModel = VehicleSearchViewModel()
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            VStack {
                TextField("Search by username or VIN", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .onChange(of: searchText) { _ in
                        viewModel.searchVehicles(searchText: searchText)
                    }

                List(viewModel.searchResults) { vehicle in
                    VehicleRowViews(vehicle: vehicle, isSelected: selectedVehicles.contains { $0.id == vehicle.id })
                        .onTapGesture {
                            toggleVehicleSelection(vehicle)
                        }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Search Vehicles")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }

    private func toggleVehicleSelection(_ vehicle: Vehicle) {
        if let index = selectedVehicles.firstIndex(where: { $0.id == vehicle.id }) {
            selectedVehicles.remove(at: index)
        } else {
            selectedVehicles.append(vehicle)
        }
    }
}

struct VehicleRowViews: View {
    let vehicle: Vehicle
    let isSelected: Bool

    var body: some View {
        HStack {
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
            VStack(alignment: .leading) {
                Text("\(vehicle.manufacturer) \(vehicle.model)")
                    .font(.headline)
                Text("Year: \(NumberFormatter.localizedString(from: NSNumber(value: vehicle.year), number: .none))")
                    .font(.subheadline)
            }
            Spacer()
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
            }
        }
    }
}

class VehicleSearchViewModel: ObservableObject {
    @Published var searchResults: [Vehicle] = []

    func searchVehicles(searchText: String) {
        guard !searchText.isEmpty else {
            self.searchResults = []
            return
        }
        
        Task {
            do {
                let result = try await AppwriteManager.shared.databases.listDocuments(
                    databaseId: AppwriteManager.shared.databaseId,
                    collectionId: "vehicles",
                    queries: [
                        Query.equal("vinNumber", value: searchText)
                    ],
                    nestedType: Vehicle.self
                )
                
                await MainActor.run {
                    self.searchResults = result.documents.map { doc -> Vehicle in
                        var vehicle = doc.data
                        vehicle.id = doc.id
                        return vehicle
                    }
                    
                    if self.searchResults.isEmpty {
                        self.searchByUsername(searchText: searchText)
                    }
                }
            } catch {
                print("Error searching vehicles: \(error.localizedDescription)")
            }
        }
    }

    private func searchByUsername(searchText: String) {
        Task {
            do {
                let result = try await AppwriteManager.shared.databases.listDocuments(
                    databaseId: AppwriteManager.shared.databaseId,
                    collectionId: AppwriteManager.shared.usersCollectionId,
                    queries: [
                        Query.equal("username", value: searchText),
                        Query.limit(1)
                    ],
                    nestedType: User.self
                )
                
                if let userDocument = result.documents.first {
                    let userUID = userDocument.data.userUID
                    self.fetchVehiclesByUser(userUID: userUID)
                }
            } catch {
                print("Error searching users: \(error.localizedDescription)")
            }
        }
    }

    private func fetchVehiclesByUser(userUID: String) {
        Task {
            do {
                let result = try await AppwriteManager.shared.databases.listDocuments(
                    databaseId: AppwriteManager.shared.databaseId,
                    collectionId: "vehicles",
                    queries: [
                        Query.equal("ownerUID", value: userUID)
                    ],
                    nestedType: Vehicle.self
                )
                
                await MainActor.run {
                    self.searchResults = result.documents.map { doc -> Vehicle in
                        var vehicle = doc.data
                        vehicle.id = doc.id
                        return vehicle
                    }
                }
            } catch {
                print("Error fetching vehicles: \(error.localizedDescription)")
            }
        }
    }
}

