//
//  UploadCarListingView.swift
//  social
//
//  Created by Naveen on 26/06/24.
//

import SwiftUI
import PhotosUI


struct UploadCarListingView: View {
    // Car details
    @State private var make: String = ""
    @State private var model: String = ""
    @State private var trim: String = ""
    @State private var year: String = ""
    @State private var price: String = ""
    @State private var mileage: String = ""
    @State private var fuelType: String = ""
    @State private var transmission: String = ""
    @State private var exteriorColor: String = ""
    @State private var interiorColor: String = ""
    @State private var bodyType: String = ""
    @State private var condition: String = ""
    @State private var features: String = ""
    @State private var location: String = ""
    @State private var description: String = ""
    @State private var contactNumber: String = ""
    
    // New fields
    @State private var vinNumber: String = ""
    @State private var drivetrain: String = ""
    @State private var engine: String = ""
    @State private var sellerType: String = ""
    
    // Image handling
    @State private var imageDatas: [Data] = []
    @State private var showImagePicker: Bool = false
    @State private var photoItems: [PhotosPickerItem] = []
    
    // User data
    @AppStorage("user_profile_url") private var profileURL: URL?
    @AppStorage("user_name") private var userName: String = ""
    @AppStorage("user_UID") private var userUID: String = ""
    
    // UI States
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading: Bool = false
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
    @State private var currentSection: FormSection = .basicInfo
    
    // Model reference
    private let viewModel = UploadCarListingViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            
            // Section selector
            sectionPickerView
                .padding(.top, 5)
            
            // Form content
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    switch currentSection {
                    case .basicInfo:
                        basicInfoSection
                    case .specifications:
                        specificationsSection
                    case .additionalDetails:
                        additionalDetailsSection
                    case .photos:
                        photosSection
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
                .animation(.easeInOut, value: currentSection)
            }
            
            footerView
        }
        .background(Color(.systemGray6))
        .photosPicker(
            isPresented: $showImagePicker,
            selection: $photoItems,
            matching: .images,
            photoLibrary: .shared()
        )
        .onChange(of: photoItems) { newValue in
            if !newValue.isEmpty {
                Task {
                    await loadImages(from: newValue)
                }
            }
        }
        .alert(errorMessage, isPresented: $showError, actions: {})
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            Button("Cancel") {
                dismiss()
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.blue)
            
            Spacer()
            
            Text("Sell Your Car")
                .font(.system(size: 18, weight: .bold))
            
            Spacer()
            
            Button(action: uploadCarListing) {
                Text("Publish")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(formIsValid ? Color.blue : Color.gray)
                    .cornerRadius(20)
            }
            .disabled(!formIsValid)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Section Picker
    private var sectionPickerView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(FormSection.allCases, id: \.self) { section in
                    VStack(spacing: 8) {
                        Text(section.rawValue)
                            .font(.system(size: 14, weight: currentSection == section ? .semibold : .regular))
                            .foregroundColor(currentSection == section ? .blue : .gray)
                        
                        // Indicator for selected section
                        Rectangle()
                            .fill(currentSection == section ? Color.blue : Color.clear)
                            .frame(height: 3)
                            .cornerRadius(2)
                    }
                    .onTapGesture {
                        withAnimation {
                            currentSection = section
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    // MARK: - Form Sections
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            sectionTitle("Basic Information")
            
            VStack(spacing: 16) {
                formField(title: "Make", placeholder: "e.g. Lamborghini", text: $make)
                formField(title: "Model", placeholder: "e.g. Aventador", text: $model)
                formField(title: "Trim", placeholder: "e.g. SV", text: $trim)
                formField(title: "Year", placeholder: "e.g. 2023", text: $year)
                    .keyboardType(.numberPad)
                formField(title: "Price ($)", placeholder: "e.g. 25000", text: $price)
                    .keyboardType(.decimalPad)
                formField(title: "Location", placeholder: "e.g. Los Angeles, CA", text: $location)
                pickerField(title: "Seller Type", selection: $sellerType, options: viewModel.sellerTypes)
            }
        }
    }
    
    private var specificationsSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            sectionTitle("Vehicle Specifications")
            
            VStack(spacing: 16) {
                formField(title: "Mileage (miles)", placeholder: "e.g. 15000", text: $mileage)
                    .keyboardType(.numberPad)
                formField(title: "VIN Number", placeholder: "e.g. 1HGBH41JXMN109186", text: $vinNumber)
                formField(title: "Engine", placeholder: "e.g. 2.5L V6", text: $engine)
                
                pickerField(title: "Fuel Type", selection: $fuelType, options: viewModel.fuelTypes)
                pickerField(title: "Transmission", selection: $transmission, options: viewModel.transmissionTypes)
                pickerField(title: "Drivetrain", selection: $drivetrain, options: viewModel.drivetrainTypes)
                pickerField(title: "Body Type", selection: $bodyType, options: viewModel.bodyTypes)
                formField(title: "Exterior Color", placeholder: "e.g. Midnight Blue", text: $exteriorColor)
                formField(title: "Interior Color", placeholder: "e.g. Beige", text: $interiorColor)
                pickerField(title: "Condition", selection: $condition, options: viewModel.conditionTypes)
            }
        }
    }
    
    private var additionalDetailsSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            sectionTitle("Additional Details")
            
            VStack(spacing: 16) {
                formField(title: "Features", placeholder: "e.g. Leather seats, Sunroof, Navigation...", text: $features)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                    
                    TextEditor(text: $description)
                        .frame(minHeight: 120)
                        .background(Color(UIColor.secondarySystemBackground)) // This will properly adapt to dark/light mode
                        .padding(10)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
                
                formField(title: "Contact Number", placeholder: "e.g. (123) 456-7890", text: $contactNumber)
                    .keyboardType(.phonePad)
            }
        }
    }
    
    private var photosSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                sectionTitle("Vehicle Photos")
                Spacer()
                Button(action: {
                    showImagePicker = true
                }) {
                    Label("Add Photos", systemImage: "plus.circle.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                }
            }
            
            if imageDatas.isEmpty {
                emptyPhotosView
            } else {
                photosGridView
            }
        }
    }
    
    private var emptyPhotosView: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("Add photos of your vehicle")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray)
            
            Text("Upload clear images from different angles")
                .font(.system(size: 14))
                .foregroundColor(.gray.opacity(0.8))
                .multilineTextAlignment(.center)
            
            Button(action: {
                showImagePicker = true
            }) {
                Text("Select Photos")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.top, 10)
        }
        .frame(maxWidth: .infinity)
        .padding(30)
        .cornerRadius(12)
    }
    
    private var photosGridView: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ],
            spacing: 12
        ) {
            ForEach(imageDatas.indices, id: \.self) { index in
                if let image = UIImage(data: imageDatas[index]) {
                    // Container for the whole cell
                    ZStack {
                        // Image
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .frame(height: 150)
                            .cornerRadius(10)
                            .clipped()
                        
                        // Overlay for the delete button with larger tap area
                        VStack {
                            HStack {
                                Spacer()
                                
                                // Delete button with explicit frame for larger tap area
                                Button {
                                    removeImage(at: index)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                        .background(Circle().fill(Color.black.opacity(0.6)))
                                }
                                .buttonStyle(PlainButtonStyle()) // Use plain style to avoid default button behavior
                                .frame(width: 44, height: 44) // Larger frame for better tap target
                                .contentShape(Rectangle()) // Use rectangle for hit testing
                                .padding(4)
                            }
                            Spacer()
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }
    
    // MARK: - Footer View
    private var footerView: some View {
        HStack {
            // Back button (when not on first section)
            if currentSection != .basicInfo {
                Button(action: {
                    moveToPreviousSection()
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.blue)
                }
            }
            
            Spacer()
            
            // Next/Submit button
            if currentSection != .photos {
                Button(action: {
                    moveToNextSection()
                }) {
                    HStack {
                        Text("Next")
                        Image(systemName: "chevron.right")
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(10)
                }
            } else {
                Button(action: uploadCarListing) {
                    Text("Publish Listing")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(formIsValid ? Color.blue : Color.gray)
                        .cornerRadius(10)
                }
                .disabled(!formIsValid)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: -2)
    }
    
    // MARK: - Navigation Methods
    private func moveToNextSection() {
        let sections = FormSection.allCases
        if let currentIndex = sections.firstIndex(of: currentSection), currentIndex < sections.count - 1 {
            withAnimation {
                currentSection = sections[currentIndex + 1]
            }
        }
    }
    
    private func moveToPreviousSection() {
        let sections = FormSection.allCases
        if let currentIndex = sections.firstIndex(of: currentSection), currentIndex > 0 {
            withAnimation {
                currentSection = sections[currentIndex - 1]
            }
        }
    }
    
    // MARK: - Image Handling
    private func loadImages(from items: [PhotosPickerItem]) async {
        for item in items {
            if let rawImageData = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: rawImageData),
               let compressedImageData = image.jpegData(compressionQuality: 0.5) {
                await MainActor.run {
                    imageDatas.append(compressedImageData)
                }
            }
        }
        
        // Clear the selection state after processing
        await MainActor.run {
            photoItems = []
        }
    }
    
    private func removeImage(at index: Int) {
        imageDatas.remove(at: index)
    }
    
    // MARK: - Form Validation
    private var formIsValid: Bool {
        !make.isEmpty &&
        !model.isEmpty &&
        !trim.isEmpty &&
        !year.isEmpty &&
        !price.isEmpty &&
        !mileage.isEmpty &&
        !fuelType.isEmpty &&
        !transmission.isEmpty &&
        !location.isEmpty &&
        !description.isEmpty &&
        !imageDatas.isEmpty
    }
    
    // MARK: - Data Upload
    private func uploadCarListing() {
        isLoading = true
        Task {
            do {
                guard let profileURL = profileURL else { return }
                let imageUrls = try await viewModel.uploadImages(imageDatas: imageDatas, userUID: userUID)
                
                let carListing = CarListing(
                    make: make,
                    model: model,
                    trim: trim,
                    year: Int(year) ?? 0,
                    price: Double(price) ?? 0.0,
                    description: description,
                    mileage: Int(mileage) ?? 0,
                    fuelType: fuelType,
                    transmission: transmission,
                    exteriorColor: exteriorColor,
                    interiorColor: interiorColor,
                    bodyType: bodyType,
                    condition: condition,
                    features: features,
                    location: location,
                    contactNumber: contactNumber,
                    vinNumber: vinNumber,
                    drivetrain: drivetrain,
                    engine: engine,
                    sellerType: sellerType,
                    imageURLs: imageUrls.urls,
                    sellerUID: userUID,
                    sellerName: userName,
                    sellerProfileURL: profileURL
                )
                
                try await viewModel.createDocumentAtFirebase(carListing)
                isLoading = false
                dismiss()
            } catch {
                await setError(error)
            }
        }
    }
    
    private func setError(_ error: Error) async {
        await MainActor.run {
            errorMessage = error.localizedDescription
            showError.toggle()
            isLoading = false
        }
    }
}

// MARK: - Preview
struct UploadCarListingView_Previews: PreviewProvider {
    static var previews: some View {
        UploadCarListingView()
    }
}
