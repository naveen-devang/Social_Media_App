//
//  UploadCarListingComponents.swift
//  social
//
//  Created by Naveen on 26/06/24.
//

import SwiftUI



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
    
    // Upload Images to Firebase Storage
    func uploadImages(imageDatas: [Data], userUID: String) async throws -> (urls: [URL], ids: [String]) {
        var imageUrls: [URL] = []
        var imageReferenceIds: [String] = []
        
        for imageData in imageDatas {
            let imageReferenceId = "\(userUID)\(Date().timeIntervalSince1970)"
            let storageRef = Storage.storage().reference().child("CarListing_Images").child(imageReferenceId)
            let _ = try await storageRef.putDataAsync(imageData)
            let downloadURL = try await storageRef.downloadURL()
            imageUrls.append(downloadURL)
            imageReferenceIds.append(imageReferenceId)
        }
        
        return (urls: imageUrls, ids: imageReferenceIds)
    }
    
    // Create document in Firestore
    func createDocumentAtFirebase(_ carListing: CarListing) async throws {
        let doc = Firestore.firestore().collection("CarListings").document()
        try doc.setData(from: carListing)
    }
}
