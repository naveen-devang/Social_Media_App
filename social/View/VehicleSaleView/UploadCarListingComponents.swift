//
//  UploadCarListingComponents.swift
//  social
//
//  Created by Naveen on 26/06/24.
//

import SwiftUI
import Appwrite

// MARK: - Form Section Enum
enum FormSection: String, CaseIterable {
    case basicInfo = "Basic Info"
    case specifications = "Specifications"
    case additionalDetails = "Additional Details"
    case photos = "Photos"
}

// MARK: - Helper Components
extension UploadCarListingView {
    // Section Title
    func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(.primary)
    }
    
    // Text Input Field
    func formField(title: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
            
            TextField(placeholder, text: text)
                .padding()
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
    }
    
    // Picker Field
    func pickerField(title: String, selection: Binding<String>, options: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
            
            Menu {
                ForEach(options, id: \.self) { option in
                    Button(option) {
                        selection.wrappedValue = option
                    }
                }
            } label: {
                HStack {
                    Text(selection.wrappedValue.isEmpty ? "Select \(title)" : selection.wrappedValue)
                        .foregroundColor(selection.wrappedValue.isEmpty ? .gray.opacity(0.8) : .primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.gray)
                }
                .padding()
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            }
        }
    }
}

// MARK: - View Model
class UploadCarListingViewModel {
    // Form Options
    let fuelTypes = ["Petrol", "Diesel", "Electric", "Hybrid", "CNG", "LPG"]
    let transmissionTypes = ["Automatic", "Manual", "Semi-Automatic", "CVT"]
    let bodyTypes = ["Sedan", "SUV", "Hatchback", "Coupe", "Convertible", "Wagon", "Van", "Truck", "Other"]
    let conditionTypes = ["Brand New", "Excellent", "Good", "Fair", "Poor"]
    let drivetrainTypes = ["FWD", "RWD", "AWD", "4WD"]
    let sellerTypes = ["Private Owner", "Dealer", "Broker", "Other"]
    
    // Upload Images to Appwrite Storage
    func uploadImages(imageDatas: [Data], userUID: String) async throws -> (urls: [URL], ids: [String]) {
        var imageUrls: [URL] = []
        var imageReferenceIds: [String] = []
        
        for imageData in imageDatas {
            let imageReferenceId = UUID().uuidString.lowercased()
            let fileId = "vehicle_\(imageReferenceId)"
            let inputFile = InputFile.fromData(imageData, filename: "car.jpg", mimeType: "image/jpeg")
            
            let file = try await AppwriteManager.shared.storage.createFile(
                bucketId: AppwriteManager.shared.bucketId,
                fileId: fileId,
                file: inputFile
            )
            
            let downloadURLString = AppwriteManager.shared.getFileViewURL(fileId: file.id)
            if let downloadURL = URL(string: downloadURLString) {
                imageUrls.append(downloadURL)
                imageReferenceIds.append(imageReferenceId)
            }
        }
        
        return (urls: imageUrls, ids: imageReferenceIds)
    }
    
    // Create document in Appwrite
    func createDocumentAtAppwrite(_ carListing: CarListing) async throws {
        _ = try await AppwriteManager.shared.databases.createDocument(
            databaseId: AppwriteManager.shared.databaseId,
            collectionId: AppwriteManager.shared.carListingsCollectionId,
            documentId: ID.unique(),
            data: carListing.toDictionary
        )
    }
}
