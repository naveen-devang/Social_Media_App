import SwiftUI
import Appwrite

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
            print("Add Vehicle button tapped")
            viewModel.addVehicle { success in
                if success {
                    print("Vehicle added successfully")
                    presentationMode.wrappedValue.dismiss()
                } else {
                    print("Failed to add vehicle")
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
    
    private func getFileIdFromURL(_ urlString: String) -> String? {
        guard let url = URL(string: urlString) else { return nil }
        let pathComponents = url.pathComponents
        if let filesIndex = pathComponents.firstIndex(of: "files"), filesIndex + 1 < pathComponents.count {
            return pathComponents[filesIndex + 1]
        }
        return nil
    }
    
    func checkVin() {
        guard !vinNumber.isEmpty else { return }

        print("Checking VIN: \(vinNumber)")

        Task {
            do {
                let result = try await AppwriteManager.shared.databases.listDocuments(
                    databaseId: AppwriteManager.shared.databaseId,
                    collectionId: "vehicles",
                    queries: [
                        Query.equal("vinNumber", value: vinNumber),
                        Query.limit(1)
                    ],
                    nestedType: Vehicle.self
                )
                
                await MainActor.run {
                    if let existingDoc = result.documents.first {
                        print("Existing vehicle found")
                        var vehicle = existingDoc.data
                        vehicle.id = existingDoc.id
                        self.existingVehicleData = vehicle
                        
                        let ownerUID = vehicle.ownerUID
                        if !ownerUID.isEmpty {
                            print("Owner UID found: \(ownerUID)")
                            
                            if ownerUID == self.userUID {
                                print("Vehicle belongs to current user")
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
            } catch {
                await MainActor.run {
                    print("Error checking VIN: \(error.localizedDescription)")
                    self.errorMessage = "Error checking VIN: \(error.localizedDescription)"
                    self.currentAlert = .error
                    self.showErrorAlert = true
                }
            }
        }
    }

    func getUsernameFromUID(_ uid: String, completion: @escaping (String) -> Void) {
        print("Fetching username for UID: \(uid)")
        
        Task {
            do {
                let result = try await AppwriteManager.shared.databases.listDocuments(
                    databaseId: AppwriteManager.shared.databaseId,
                    collectionId: AppwriteManager.shared.usersCollectionId,
                    queries: [
                        Query.equal("userUID", value: uid),
                        Query.limit(1)
                    ],
                    nestedType: User.self
                )
                
                if let userDoc = result.documents.first {
                    print("Successfully retrieved username: \(userDoc.data.username)")
                    completion(userDoc.data.username)
                } else {
                    print("No user document found for UID: \(uid)")
                    completion("Unknown User")
                }
            } catch {
                print("Error fetching username: \(error.localizedDescription)")
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
        existingImageUrls = vehicle.imageUrls ?? []
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
        
        Task {
            do {
                // 1. Upload new images to profile-images bucket
                var uploadedUrls: [String] = []
                for (index, image) in selectedImages.enumerated() {
                    guard let imageData = image.jpegData(compressionQuality: 0.8) else { continue }
                    let imageRefId = UUID().uuidString
                    let fileId = "vehicle_\(imageRefId)"
                    
                    _ = try await AppwriteManager.shared.storage.createFile(
                        bucketId: AppwriteManager.shared.bucketId,
                        fileId: fileId,
                        file: InputFile.fromData(imageData, filename: "\(fileId).jpg", mimeType: "image/jpeg")
                    )
                    
                    let downloadUrl = AppwriteManager.shared.getFileViewURL(fileId: fileId)
                    uploadedUrls.append(downloadUrl)
                }
                
                // 2. Remove deleted images from Appwrite Storage
                for imageUrl in removedImageUrls {
                    if let fileId = getFileIdFromURL(imageUrl) {
                        try? await AppwriteManager.shared.storage.deleteFile(
                            bucketId: AppwriteManager.shared.bucketId,
                            fileId: fileId
                        )
                    }
                }
                
                let finalImageUrls = existingImageUrls + uploadedUrls
                
                // 3. Save vehicle document to databases
                let result = try await AppwriteManager.shared.databases.listDocuments(
                    databaseId: AppwriteManager.shared.databaseId,
                    collectionId: "vehicles",
                    queries: [
                        Query.equal("vinNumber", value: vinNumber),
                        Query.limit(1)
                    ],
                    nestedType: Vehicle.self
                )
                
                if let existingDoc = result.documents.first {
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
                        "ownerUID": self.userUID,
                        "imageUrls": finalImageUrls
                    ]
                    
                    _ = try await AppwriteManager.shared.databases.updateDocument(
                        databaseId: AppwriteManager.shared.databaseId,
                        collectionId: "vehicles",
                        documentId: existingDoc.id,
                        data: updatedData
                    )
                } else {
                    print("No existing vehicle found, adding new vehicle...")
                    let vehicleID = "\(userUID)_\(UUID().uuidString)"
                    
                    let vehicle = Vehicle(
                        manufacturer: manufacturer,
                        model: model,
                        year: yearInt,
                        interiorColor: interiorColor,
                        exteriorColor: exteriorColor,
                        vinNumber: vinNumber,
                        mileage: mileageInt,
                        engine: engine,
                        description: description,
                        ownerUID: userUID,
                        imageUrls: finalImageUrls,
                        vehicleID: vehicleID,
                        isActive: true
                    )
                    
                    _ = try await AppwriteManager.shared.databases.createDocument(
                        databaseId: AppwriteManager.shared.databaseId,
                        collectionId: "vehicles",
                        documentId: ID.unique(),
                        data: vehicle.toDictionary
                    )
                }
                
                await MainActor.run {
                    completion(true)
                }
            } catch {
                await MainActor.run {
                    print("Error saving vehicle: \(error.localizedDescription)")
                    self.errorMessage = "Error saving vehicle: \(error.localizedDescription)"
                    self.showErrorAlert = true
                    completion(false)
                }
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

