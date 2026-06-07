//
//  AddVehicleView.swift
//  social
//
//  Created by デバン・ナビーン on 04/03/24.
//

// AddVehicleView.swift

import SwiftUI



struct AddVehicleView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = AddVehicleViewModel()
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            Form {
                vehicleDetailsSection
                imagesSection
            }
            .navigationTitle("Add Vehicle")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    cancelButton
                }
            }
            .sheet(isPresented: $viewModel.isShowingImagePicker) {
                ImagePicker(images: $viewModel.selectedImages)
            }
            .alert(isPresented: $viewModel.showErrorAlert) {
                Alert(title: Text("Error"), message: Text(viewModel.errorMessage), dismissButton: .default(Text("OK")))
            }
            // In AddVehicleView:
            .alert(isPresented: Binding(
                get: { viewModel.currentAlert != .none },
                set: { if !$0 { viewModel.currentAlert = .none } }
            )) {
                switch viewModel.currentAlert {
                case .error:
                    Alert(
                        title: Text("Error"),
                        message: Text(viewModel.errorMessage),
                        dismissButton: .default(Text("OK"))
                    )
                case .vinCheck:
                    Alert(
                        title: Text("VIN Check"),
                        message: Text(viewModel.vinAlertMessage),
                        dismissButton: .default(Text("OK"))
                    )
                case .existingData:
                    Alert(
                        title: Text("Existing Vehicle Data"),
                        message: Text(viewModel.vinAlertMessage),
                        primaryButton: .default(Text("Use Existing Data"), action: viewModel.useExistingData),
                        secondaryButton: .cancel()
                    )
                case .none:
                    Alert(title: Text(""))  // This should never be shown
                }
            }
        }
        HStack {
            addVehicleButton
                .padding()
        }
    }
    
    private var vehicleDetailsSection: some View {
        Section(header: Text("Vehicle Details")) {
            TextField("Manufacturer", text: $viewModel.manufacturer)
            TextField("Model", text: $viewModel.model)
            yearTextField
            TextField("Interior Color", text: $viewModel.interiorColor)
            TextField("Exterior Color", text: $viewModel.exteriorColor)
            TextField("VIN Number", text: $viewModel.vinNumber)
                .onChange(of: viewModel.vinNumber) { _ in viewModel.checkVin() }
            TextField("Mileage", text: $viewModel.mileage)
                .keyboardType(.numberPad)
            TextField("Engine", text: $viewModel.engine)
            TextField("Description", text: $viewModel.description, axis: .vertical)
                .lineLimit(3...6)
        }
    }

    private var imagesSection: some View {
        Section(header: Text("Vehicle Images")) {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    addPhotoButton
                    
                    // Existing images from URLs
                    ForEach(viewModel.existingImageUrls, id: \.self) { imageUrl in
                        imageContainer(imageUrl: imageUrl, isExisting: true)
                    }
                    
                    // New selected images
                    ForEach(viewModel.selectedImages, id: \.self) { image in
                        imageContainer(image: image, isExisting: false)
                    }
                }
            }
        }
    }

    private func imageContainer(imageUrl: String? = nil, image: UIImage? = nil, isExisting: Bool) -> some View {
        ZStack(alignment: .topTrailing) {
            // Image loading
            if let imageUrl = imageUrl {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image.resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .clipped()
                        .cornerRadius(10)
                } placeholder: {
                    Color.gray.opacity(0.2)
                        .frame(width: 100, height: 100)
                        .cornerRadius(10)
                }
            } else if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipped()
                    .cornerRadius(10)
            }
            
            // Delete button
            Button(action: {
                if isExisting, let imageUrl = imageUrl {
                    viewModel.removeExistingImage(imageUrl)
                } else if let image = image {
                    viewModel.removeNewImage(image)
                }
            }) {
                Image(systemName: "xmark")
                    .foregroundColor(.white)
                    .padding(4)
                    .background(Color.red.opacity(0.8))
                    .clipShape(Circle())
            }
            .offset(x: 5, y: -5)
            .shadow(color: .black.opacity(0.2), radius: 2, x: 1, y: 1)
        }
        .frame(width: 100, height: 100)
    }
    
    private var yearTextField: some View {
        TextField("Year", text: $viewModel.year)
            .keyboardType(.numberPad)
            .foregroundColor(viewModel.isYearValid ? .primary : .red)
            .onChange(of: viewModel.year) { viewModel.validateYear($0) }
    }
    
    private var addPhotoButton: some View {
        Button(action: { viewModel.isShowingImagePicker = true }) {
            Image(systemName: "plus.circle.fill")
                .font(.title)
                .foregroundColor(.blue)
        }
        .frame(width: 100, height: 100)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(8)
    }
    
    private var addVehicleButton: some View {
        Button("Add Vehicle") {
            print("Add Vehicle button tapped") // Add this debug print
            viewModel.addVehicle { success in
                if success {
                    print("Vehicle added successfully") // Add this debug print
                    presentationMode.wrappedValue.dismiss()
                } else {
                    print("Failed to add vehicle") // Add this debug print
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 50)
        .background(Color.green)
        .foregroundColor(.white)
        .cornerRadius(10)
        .disabled(!viewModel.isFormValid)
    }
    
    private var cancelButton: some View {
        Button("Cancel") {
            presentationMode.wrappedValue.dismiss()
        }
        .foregroundStyle(.blue)
    }
}

class AddVehicleViewModel: ObservableObject {
    @Published var manufacturer = ""
    @Published var model = ""
    @Published var year = ""
    @Published var interiorColor = ""
    @Published var exteriorColor = ""
    @Published var vinNumber = ""
    @Published var mileage = ""
    @Published var engine = ""
    @Published var description = ""
    @Published var selectedImages: [UIImage] = []
    @Published var isShowingImagePicker = false
    @Published var isYearValid = true
    @Published var showErrorAlert = false
    @Published var errorMessage = ""
    @Published var showVinAlert = false
    @Published var vinAlertMessage = ""
    @Published var existingVehicleData: Vehicle?
    @Published var showExistingDataPrompt = false
    @Published var existingImageUrls: [String] = []
    @Published var removedImageUrls: [String] = []
    
    @Published var canEditVehicle = true

    
    @AppStorage("user_UID") private var userUID: String = ""
    
    var isFormValid: Bool {
        !manufacturer.isEmpty && !model.isEmpty && isYearValid && !year.isEmpty && canEditVehicle
    }

    
    func validateYear(_ newValue: String) {
        isYearValid = newValue.count == 4 && Int(newValue) != nil
    }
    
    enum AlertType {
        case error
        case vinCheck
        case existingData
        case none
    }
    
    @Published var currentAlert: AlertType = .none
    
    // First, let's add proper debug logging to track the flow
    func checkVin() {
        guard !vinNumber.isEmpty else { return }

        print("Checking VIN: \(vinNumber)")

        let db = Firestore.firestore()
        db.collection("Vehicles")
            .whereField("vinNumber", isEqualTo: vinNumber)
            .getDocuments { [weak self] (querySnapshot, err) in
                guard let self = self else { return }

                DispatchQueue.main.async {
                    if let err = err {
                        print("Error checking VIN: \(err.localizedDescription)")
                        self.errorMessage = "Error checking VIN: \(err.localizedDescription)"
                        self.currentAlert = .error
                        self.showErrorAlert = true
                        return
                    }

                    if let existingVehicle = querySnapshot?.documents.first {
                        print("Existing vehicle found")
                        
                        let vehicleData = existingVehicle.data()
                        if let ownerUID = vehicleData["ownerUID"] as? String, !ownerUID.isEmpty {
                            print("Owner UID found: \(ownerUID)")
                            
                            if ownerUID == self.userUID {
                                print("Vehicle belongs to current user")
                                let vehicle = try? existingVehicle.data(as: Vehicle.self)
                                self.existingVehicleData = vehicle
                                self.vinAlertMessage = "This is your vehicle. You can update its details."
                                self.currentAlert = .vinCheck
                                self.showVinAlert = true
                                self.canEditVehicle = true
                                
                            } else {
                                print("Vehicle belongs to another user")
                                self.getUsernameFromUID(ownerUID) { username in
                                    DispatchQueue.main.async {
                                        print("Retrieved username: \(username)")
                                        self.vinAlertMessage = "This VIN is associated with \(username)'s garage. You cannot edit or create a new entry for this vehicle. Please contact \(username) if you want to be added to their garage."
                                        self.canEditVehicle = false
                                        self.currentAlert = .vinCheck
                                        self.showVinAlert = true
                                        self.showExistingDataPrompt = false
                                    }
                                }
                            }
                        } else {
                            print("Vehicle exists but has no owner")
                            let vehicle = try? existingVehicle.data(as: Vehicle.self)
                            self.existingVehicleData = vehicle
                            self.vinAlertMessage = "This VIN exists in the database. Would you like to use the existing data?"
                            self.currentAlert = .existingData
                            self.showExistingDataPrompt = true
                            self.canEditVehicle = true
                        }
                    } else {
                        print("No existing vehicle found for VIN: \(self.vinNumber)")
                        self.canEditVehicle = true
                        self.currentAlert = .none
                        self.showVinAlert = false
                        self.showExistingDataPrompt = false
                    }
                }
            }
    }

    func getUsernameFromUID(_ uid: String, completion: @escaping (String) -> Void) {
        print("Fetching username for UID: \(uid)")
        
        let db = Firestore.firestore()
        db.collection("Users")
            .whereField("userUID", isEqualTo: uid)
            .getDocuments { querySnapshot, error in
                if let error = error {
                    print("Error fetching username: \(error.localizedDescription)")
                    completion("Unknown User")
                    return
                }
                
                guard let document = querySnapshot?.documents.first else {
                    print("No user document found for UID: \(uid)")
                    completion("Unknown User")
                    return
                }
                
                do {
                    let user = try document.data(as: User.self)
                    print("Successfully retrieved username: \(user.username)")
                    completion(user.username)
                } catch {
                    print("Error decoding user document: \(error.localizedDescription)")
                    print("Document data: \(document.data())")
                    completion("Unknown User")
                }
            }
    }
    
    func useExistingData() {
        guard let vehicle = existingVehicleData else { return }
        manufacturer = vehicle.manufacturer
        model = vehicle.model
        year = String(vehicle.year)
        interiorColor = vehicle.interiorColor
        exteriorColor = vehicle.exteriorColor
        mileage = String(vehicle.mileage)
        engine = vehicle.engine
        description = vehicle.description
        existingImageUrls = vehicle.imageUrls ?? [] // Safely unwrap optional array
        showExistingDataPrompt = false
    }
    
    func removeExistingImage(_ imageUrl: String) {
        existingImageUrls.removeAll { $0 == imageUrl }
        removedImageUrls.append(imageUrl)
    }

    func removeNewImage(_ image: UIImage) {
        selectedImages.removeAll { $0 == image }
    }

    
    
    func addVehicle(completion: @escaping (Bool) -> Void) {
        print("Adding vehicle...")
        guard let yearInt = Int(year), let mileageInt = Int(mileage) else {
            print("Invalid year or mileage")
            self.errorMessage = "Invalid year or mileage"
            self.showErrorAlert = true
            completion(false)
            return
        }
        
        let db = Firestore.firestore()
        
        db.collection("Vehicles")
            .whereField("vinNumber", isEqualTo: vinNumber)
            .getDocuments { [weak self] (querySnapshot, err) in
                guard let self = self else { return }
                
                if let err = err {
                    print("Error checking for existing vehicle: \(err.localizedDescription)")
                    self.errorMessage = "Error checking for existing vehicle: \(err.localizedDescription)"
                    self.showErrorAlert = true
                    completion(false)
                    return
                }
                
                if let existingVehicle = querySnapshot?.documents.first {
                    print("Existing vehicle found, updating...")
                    let updatedData: [String: Any] = [
                        "manufacturer": self.manufacturer,
                        "model": self.model,
                        "year": yearInt,
                        "interiorColor": self.interiorColor,
                        "exteriorColor": self.exteriorColor,
                        "mileage": mileageInt,
                        "engine": self.engine,
                        "description": self.description,
                        "isActive": true,
                        "ownerUID": self.userUID
                    ]
                    
                    existingVehicle.reference.updateData(updatedData) { error in
                        if let error = error {
                            print("Error updating vehicle: \(error.localizedDescription)")
                            self.errorMessage = "Error updating vehicle: \(error.localizedDescription)"
                            self.showErrorAlert = true
                            completion(false)
                        } else {
                            print("Vehicle updated successfully")
                            self.updateImages(for: existingVehicle.reference, completion: completion)
                        }
                    }
                } else {
                    print("No existing vehicle found, adding new vehicle...")
                    self.addNewVehicle(yearInt: yearInt, mileageInt: mileageInt, completion: completion)
                }
            }
    }
    
    private func updateImages(for documentRef: DocumentReference, completion: @escaping (Bool) -> Void) {
        let group = DispatchGroup()

        // Remove images
        for imageUrl in removedImageUrls {
            group.enter()
            Storage.storage().reference(forURL: imageUrl).delete { error in
                if let error = error {
                    print("Error deleting image: \(error.localizedDescription)")
                }
                group.leave()
            }
        }

        // Upload new images
        for (index, image) in selectedImages.enumerated() {
            group.enter()
            uploadImage(image, index: index, to: documentRef) {
                group.leave()
            }
        }

        group.notify(queue: .main) {
            documentRef.updateData([
                "imageUrls": self.existingImageUrls
            ]) { error in
                if let error = error {
                    print("Error updating document with imageUrls: \(error.localizedDescription)")
                    completion(false)
                } else {
                    print("Vehicle images updated successfully")
                    completion(true)
                }
            }
        }
    }
    
    private func addNewVehicle(yearInt: Int, mileageInt: Int, completion: @escaping (Bool) -> Void) {
        let vehicleID = "\(userUID)_\(UUID().uuidString)"
        
        let vehicle = Vehicle(manufacturer: manufacturer,
                              model: model,
                              year: yearInt,
                              interiorColor: interiorColor,
                              exteriorColor: exteriorColor,
                              vinNumber: vinNumber,
                              mileage: mileageInt,
                              engine: engine,
                              description: description,
                              ownerUID: userUID,
                              imageUrls: [],
                              vehicleID: vehicleID,
                              isActive: true)
        
        do {
            print("Attempting to add new vehicle to Firestore...")
            let documentRef = try Firestore.firestore().collection("Vehicles").addDocument(from: vehicle)
            print("Vehicle added successfully. Document ID: \(documentRef.documentID)")
            uploadImages(for: documentRef)
            completion(true)
        } catch {
            print("Error adding vehicle: \(error.localizedDescription)")
            self.errorMessage = "Error adding vehicle: \(error.localizedDescription)"
            self.showErrorAlert = true
            completion(false)
        }
    }
    
    private func uploadImages(for documentRef: DocumentReference) {
        for (index, image) in selectedImages.enumerated() {
            guard let imageData = image.jpegData(compressionQuality: 0.8) else { continue }
            
            let imageName = "\(UUID().uuidString)_\(index)"
            let storageRef = Storage.storage().reference().child("VehicleImages/\(imageName)")
            
            storageRef.putData(imageData, metadata: nil) { metadata, error in
                guard metadata != nil else {
                    print("Error uploading image: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                storageRef.downloadURL { url, error in
                    guard let downloadURL = url else {
                        print("Error getting download URL: \(error?.localizedDescription ?? "Unknown error")")
                        return
                    }
                    
                    documentRef.updateData([
                        "imageUrls": FieldValue.arrayUnion([downloadURL.absoluteString])
                    ]) { error in
                        if let error = error {
                            print("Error updating document with imageUrls: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
    }
    
    private func uploadImage(_ image: UIImage, index: Int, to documentRef: DocumentReference, completion: @escaping () -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion()
            return
        }

        let imageName = "\(UUID().uuidString)_\(index)"
        let storageRef = Storage.storage().reference().child("VehicleImages/\(imageName)")

        storageRef.putData(imageData, metadata: nil) { metadata, error in
            guard metadata != nil else {
                print("Error uploading image: \(error?.localizedDescription ?? "Unknown error")")
                completion()
                return
            }

            storageRef.downloadURL { url, error in
                guard let downloadURL = url else {
                    print("Error getting download URL: \(error?.localizedDescription ?? "Unknown error")")
                    completion()
                    return
                }

                self.existingImageUrls.append(downloadURL.absoluteString)
                completion()
            }
        }
    }
}

struct ImageFullScreenView: View {
    let image: UIImage

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .edgesIgnoringSafeArea(.all)
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) private var presentationMode
    @Binding var images: [UIImage]

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let selectedImage = info[.originalImage] as? UIImage {
                parent.images.append(selectedImage)
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
