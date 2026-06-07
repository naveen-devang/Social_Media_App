//
//  VehicleDetailView.swift
//  social
//
//  Created by デバン・ナビーン on 06/03/24.
//

import SwiftUI
import SDWebImageSwiftUI
import Appwrite




struct ImageScrollView: UIViewRepresentable {
    let imageUrl: String

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.maximumZoomScale = 5.0
        scrollView.minimumZoomScale = 1.0

        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        scrollView.addSubview(imageView)
        
        if let url = URL(string: imageUrl) {
            imageView.sd_setImage(with: url)
        }

        imageView.frame = scrollView.bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        return scrollView
    }

    func updateUIView(_ uiView: UIScrollView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, UIScrollViewDelegate {
        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return scrollView.subviews.first
        }
    }
}

struct VehicleDetailView: View {
    let vehicle: Vehicle
    @StateObject private var viewModel: VehicleDetailViewModel
    @State private var isEditing = false
    @State private var editedVehicle: Vehicle

    init(vehicle: Vehicle) {
        self.vehicle = vehicle
        self._editedVehicle = State(initialValue: vehicle)
        self._viewModel = StateObject(wrappedValue: VehicleDetailViewModel(vehicle: vehicle))
    }
    
    private var editHistoryButton: some View {
        NavigationLink(destination: EditHistoryView(vehicleID: vehicle.id ?? "")) {
            Image(systemName: "clock.arrow.circlepath")
        }
    }
    
    private var navigationBarItems: some View {
        HStack {
            Button("Edit") {
                isEditing.toggle()
            }
            editHistoryButton
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
        .navigationBarItems(trailing: navigationBarItems)
        .sheet(isPresented: $isEditing) {
            EditVehicleView(vehicle: $editedVehicle, isPresented: $isEditing)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Vehicle Detail")
        .overlay(
            Divider()
                .background(Color.gray)
                .frame(height: 1),
            alignment: .bottom
        )
        .onAppear {
            viewModel.fetchTaggedPosts()
        }
    }
}

struct TaggedPostsGridView: View {
    let posts: [Post]
    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(posts) { post in
                NavigationLink(destination: PostCardScrollView(posts: posts, selectedPost: post)) {
                    PostThumbnail(post: post)
                }
            }
        }
    }
}

struct PostCardScrollView: View {
    let posts: [Post]
    let selectedPost: Post
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                PostCardView(
                    post: selectedPost,
                    onUpdate: { _ in },
                    onDelete: {}
                )
                
                ForEach(posts.filter { $0.id != selectedPost.id }) { post in
                    PostCardView(
                        post: post,
                        onUpdate: { _ in },
                        onDelete: {}
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Tagged Posts")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PostThumbnail: View {
    let post: Post
    
    var body: some View {
        VStack {
            if let imageURL = post.imageURL {
                WebImage(url: imageURL)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipped()
            } else {
                Text(post.text)
                    .lineLimit(3)
                    .frame(width: 100, height: 100)
                    .background(Color.gray.opacity(0.2))
            }
        }
        .cornerRadius(10)
    }
}

class VehicleDetailViewModel: ObservableObject {
    @Published var taggedPosts: [Post] = []
    private let vehicle: Vehicle
    
    init(vehicle: Vehicle) {
        self.vehicle = vehicle
    }
    
    func fetchTaggedPosts() {
        guard let vehicleID = vehicle.id else { return }
        Task {
            do {
                let result = try await AppwriteManager.shared.databases.listDocuments(
                    databaseId: AppwriteManager.shared.databaseId,
                    collectionId: AppwriteManager.shared.postsCollectionId,
                    queries: [
                        Query.contains("taggedVehicleIDs", value: [vehicleID])
                    ],
                    nestedType: Post.self
                )
                await MainActor.run {
                    self.taggedPosts = result.documents.map { doc -> Post in
                        var post = doc.data
                        post.id = doc.id
                        return post
                    }
                }
            } catch {
                print("Error fetching tagged posts: \(error.localizedDescription)")
            }
        }
    }
}

struct ImageIndex: Identifiable {
    let id: Int
}

struct ImageCarousel: View {
    let imageUrls: [String]
    @State private var selectedImageIndex: ImageIndex?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Array(imageUrls.enumerated()), id: \.offset) { index, imageUrl in
                    WebImage(url: URL(string: imageUrl))
                        .resizable()
                        .scaledToFill()
                        .frame(width: 300, height: 200)
                        .cornerRadius(10)
                        .clipped()
                        .onTapGesture {
                            selectedImageIndex = ImageIndex(id: index)
                        }
                }
            }
            .padding(.horizontal, 5)
        }
        .fullScreenCover(item: $selectedImageIndex) { imageIndex in
            ZStack {
                Color.black.ignoresSafeArea()
                TabView(selection: .constant(imageIndex.id)) {
                    ForEach(Array(imageUrls.enumerated()), id: \.offset) { idx, url in
                        AsyncImage(url: URL(string: url)) { image in
                            image.resizable().scaledToFit()
                        } placeholder: {
                            ProgressView()
                        }
                        .tag(idx)
                    }
                }
                .tabViewStyle(.page)
            }
        }
    }
}

struct VehicleDetail: Hashable {
    let title: String
    let value: String
}

struct VehicleDetailTable: View {
    let vehicle: Vehicle

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(vehicleDetails, id: \.self) { detail in
                VehicleDetailRow(detail: detail)
            }
        }
        .padding()
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray, lineWidth: 1)
        )
    }

    private var vehicleDetails: [VehicleDetail] {
        [
            VehicleDetail(title: "Year", value: NumberFormatter.localizedString(from: NSNumber(value: vehicle.year), number: .none)),
            VehicleDetail(title: "Manufacturer", value: vehicle.manufacturer.isEmpty ? "N/A" : vehicle.manufacturer),
            VehicleDetail(title: "Model", value: vehicle.model.isEmpty ? "N/A" : vehicle.model),
            VehicleDetail(title: "VIN", value: vehicle.vinNumber.isEmpty ? "N/A" : vehicle.vinNumber),
            VehicleDetail(title: "Interior Color", value: vehicle.interiorColor.isEmpty ? "N/A" : vehicle.interiorColor),
            VehicleDetail(title: "Exterior Color", value: vehicle.exteriorColor.isEmpty ? "N/A" : vehicle.exteriorColor),
            VehicleDetail(title: "Mileage", value: vehicle.mileage == 0 ? "N/A" : "\(vehicle.mileage)"),
            VehicleDetail(title: "Engine", value: vehicle.engine.isEmpty ? "N/A" : vehicle.engine),
            VehicleDetail(title: "Description", value: vehicle.description.isEmpty ? "N/A" : vehicle.description)
        ]
    }
}

struct VehicleDetailRow: View {
    let detail: VehicleDetail
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(detail.title)
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(detail.value)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal)
            
            Spacer().frame(height: 10)
            
            if detail.title != "Description" {
                Divider()
                    .background(Color.gray)
                    .frame(height: 1)
            }
        }
    }
}

class ImageCache {
    static let shared = ImageCache()
    private var cache = NSCache<NSString, UIImage>()
    
    func get(key: String) -> UIImage? {
        return cache.object(forKey: key as NSString)
    }
    
    func set(image: UIImage, key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
}

struct EditVehicleView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel: EditVehicleViewModel
    @Binding var vehicle: Vehicle
    @Binding var isPresented: Bool
    @State private var showDeleteConfirmation = false
    @State private var errorMessage = ""
    @State private var showError = false
    
    init(vehicle: Binding<Vehicle>, isPresented: Binding<Bool>) {
        self._vehicle = vehicle
        self._isPresented = isPresented
        self._viewModel = StateObject(wrappedValue: EditVehicleViewModel(vehicle: vehicle.wrappedValue))
    }
    
    var body: some View {
        NavigationView {
            Form {
                vehicleDetailsSection
                imagesSection
            }
            .navigationTitle("Edit Vehicle")
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
            .alert(isPresented: $showDeleteConfirmation) {
                Alert(
                    title: Text("Confirm Deletion"),
                    message: Text("Are you sure you want to delete this vehicle? This action cannot be undone."),
                    primaryButton: .destructive(Text("Delete"), action: deleteVehicle),
                    secondaryButton: .cancel()
                )
            }
        }
        HStack {
            updateVehicleButton
            deleteVehicleButton
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
            if let imageUrl = imageUrl {
                CachedAsyncImage(url: imageUrl)
                    .cornerRadius(10)
            } else if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipped()
                    .cornerRadius(10)
            }
            
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

    struct CachedAsyncImage: View {
        let url: String
        @State private var image: UIImage?
        
        var body: some View {
            Group {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .clipped()
                } else {
                    ProgressView()
                        .frame(width: 100, height: 100)
                        .onAppear {
                            loadImage()
                        }
                }
            }
        }
        
        private func loadImage() {
            if let cachedImage = ImageCache.shared.get(key: url) {
                self.image = cachedImage
                return
            }
            
            guard let imageUrl = URL(string: url) else { return }
            
            URLSession.shared.dataTask(with: imageUrl) { data, _, _ in
                if let data = data, let downloadedImage = UIImage(data: data) {
                    DispatchQueue.main.async {
                        ImageCache.shared.set(image: downloadedImage, key: url)
                        self.image = downloadedImage
                    }
                }
            }.resume()
        }
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
    
    private var updateVehicleButton: some View {
        Button("Update Vehicle") {
            viewModel.updateVehicle { success in
                if success {
                    vehicle.manufacturer = viewModel.manufacturer
                    vehicle.model = viewModel.model
                    vehicle.year = Int(viewModel.year) ?? vehicle.year
                    vehicle.interiorColor = viewModel.interiorColor
                    vehicle.exteriorColor = viewModel.exteriorColor
                    vehicle.vinNumber = viewModel.vinNumber
                    vehicle.mileage = Int(viewModel.mileage) ?? vehicle.mileage
                    vehicle.engine = viewModel.engine
                    vehicle.description = viewModel.description
                    vehicle.imageUrls = viewModel.existingImageUrls
                    
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 50)
        .background(Color.green)
        .foregroundColor(.white)
        .cornerRadius(10)
        .disabled(!viewModel.isFormValid)
    }
    
    private var deleteVehicleButton: some View {
        Button("Delete Vehicle") {
            showDeleteConfirmation.toggle()
        }
        .frame(maxWidth: .infinity, maxHeight: 50)
        .background(Color.red)
        .foregroundColor(.white)
        .cornerRadius(10)
    }
    
    private var cancelButton: some View {
        Button("Cancel") {
            presentationMode.wrappedValue.dismiss()
        }
        .foregroundStyle(.blue)
    }
    
    func deleteVehicle() {
        guard let vehicleID = vehicle.id else {
            showError(message: "Error: Vehicle ID is nil")
            return
        }

        Task {
            do {
                _ = try await AppwriteManager.shared.databases.updateDocument(
                    databaseId: AppwriteManager.shared.databaseId,
                    collectionId: "vehicles",
                    documentId: vehicleID,
                    data: [
                        "isActive": false,
                        "ownerUID": ""
                    ]
                )
                await MainActor.run {
                    isPresented = false
                }
            } catch {
                await MainActor.run {
                    showError(message: "Error removing vehicle from garage: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}

class EditVehicleViewModel: ObservableObject {
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
    @Published var existingImageUrls: [String] = []
    @Published var removedImageUrls: [String] = []
    
    @AppStorage("user_UID") private var userUID: String = ""
    
    private let originalVehicle: Vehicle
    
    init(vehicle: Vehicle) {
        self.originalVehicle = vehicle
        self.manufacturer = vehicle.manufacturer
        self.model = vehicle.model
        self.year = String(vehicle.year)
        self.interiorColor = vehicle.interiorColor
        self.exteriorColor = vehicle.exteriorColor
        self.vinNumber = vehicle.vinNumber
        self.mileage = String(vehicle.mileage)
        self.engine = vehicle.engine
        self.description = vehicle.description
        self.existingImageUrls = vehicle.imageUrls ?? []
        self.isYearValid = true
    }
    
    var isFormValid: Bool {
        !manufacturer.isEmpty && !model.isEmpty && isYearValid && !year.isEmpty
    }
    
    func validateYear(_ newValue: String) {
        isYearValid = newValue.count == 4 && Int(newValue) != nil
    }
    
    func removeExistingImage(_ imageUrl: String) {
        existingImageUrls.removeAll { $0 == imageUrl }
        removedImageUrls.append(imageUrl)
    }

    func removeNewImage(_ image: UIImage) {
        selectedImages.removeAll { $0 == image }
    }
    
    private func getFileIdFromURL(_ urlString: String) -> String? {
        guard let url = URL(string: urlString) else { return nil }
        let pathComponents = url.pathComponents
        if let filesIndex = pathComponents.firstIndex(of: "files"), filesIndex + 1 < pathComponents.count {
            return pathComponents[filesIndex + 1]
        }
        return nil
    }
    
    func updateVehicle(completion: @escaping (Bool) -> Void) {
        guard let yearInt = Int(year), let mileageInt = Int(mileage) else {
            self.errorMessage = "Invalid year or mileage"
            self.showErrorAlert = true
            completion(false)
            return
        }
        
        guard let vehicleID = originalVehicle.id else {
            self.errorMessage = "Error: Vehicle ID is missing"
            self.showErrorAlert = true
            completion(false)
            return
        }
        
        // Track edited fields
        var editedFields: [EditedField] = []
        var updatedData: [String: Any] = [:]

        if originalVehicle.manufacturer != manufacturer {
            editedFields.append(EditedField(
                fieldName: "Manufacturer",
                previousValue: originalVehicle.manufacturer,
                newValue: manufacturer
            ))
            updatedData["manufacturer"] = manufacturer
        }

        if originalVehicle.model != model {
            editedFields.append(EditedField(
                fieldName: "Model",
                previousValue: originalVehicle.model,
                newValue: model
            ))
            updatedData["model"] = model
        }

        if originalVehicle.year != yearInt {
            editedFields.append(EditedField(
                fieldName: "Year",
                previousValue: String(originalVehicle.year),
                newValue: year
            ))
            updatedData["year"] = yearInt
        }

        if originalVehicle.interiorColor != interiorColor {
            editedFields.append(EditedField(
                fieldName: "Interior Color",
                previousValue: originalVehicle.interiorColor,
                newValue: interiorColor
            ))
            updatedData["interiorColor"] = interiorColor
        }

        if originalVehicle.exteriorColor != exteriorColor {
            editedFields.append(EditedField(
                fieldName: "Exterior Color",
                previousValue: originalVehicle.exteriorColor,
                newValue: exteriorColor
            ))
            updatedData["exteriorColor"] = exteriorColor
        }

        if originalVehicle.vinNumber != vinNumber {
            editedFields.append(EditedField(
                fieldName: "Vin Number",
                previousValue: originalVehicle.vinNumber,
                newValue: vinNumber
            ))
            updatedData["vinNumber"] = vinNumber
        }

        if originalVehicle.mileage != mileageInt {
            editedFields.append(EditedField(
                fieldName: "Mileage",
                previousValue: String(originalVehicle.mileage),
                newValue: mileage
            ))
            updatedData["mileage"] = mileageInt
        }

        if originalVehicle.engine != engine {
            editedFields.append(EditedField(
                fieldName: "Engine",
                previousValue: originalVehicle.engine,
                newValue: engine
            ))
            updatedData["engine"] = engine
        }

        if originalVehicle.description != description {
            editedFields.append(EditedField(
                fieldName: "Description",
                previousValue: originalVehicle.description,
                newValue: description
            ))
            updatedData["description"] = description
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
                updatedData["imageUrls"] = finalImageUrls
                
                // 3. Update database document
                _ = try await AppwriteManager.shared.databases.updateDocument(
                    databaseId: AppwriteManager.shared.databaseId,
                    collectionId: "vehicles",
                    documentId: vehicleID,
                    data: updatedData
                )
                
                // 4. Record edit history if fields were changed
                if !editedFields.isEmpty {
                    self.recordEditHistory(vehicleID: vehicleID, editedFields: editedFields)
                }
                
                await MainActor.run {
                    self.existingImageUrls = finalImageUrls
                    self.selectedImages = []
                    self.removedImageUrls = []
                    completion(true)
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Error updating vehicle: \(error.localizedDescription)"
                    self.showErrorAlert = true
                    completion(false)
                }
            }
        }
    }
    
    private func recordEditHistory(vehicleID: String, editedFields: [EditedField]) {
        getUserName { [weak self] username in
            guard let self = self else { return }
            
            let editEntry = VehicleEdit(
                id: nil,
                vehicleID: vehicleID,
                editorUID: self.userUID,
                editorName: username,
                editedFields: editedFields,
                timestamp: Date()
            )
            
            Task {
                do {
                    _ = try await AppwriteManager.shared.databases.createDocument(
                        databaseId: AppwriteManager.shared.databaseId,
                        collectionId: "edit_history",
                        documentId: ID.unique(),
                        data: editEntry.toDictionary
                    )
                } catch {
                    print("Error recording edit history: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func getUserName(completion: @escaping (String) -> Void) {
        guard !userUID.isEmpty else {
            completion("Unknown User")
            return
        }
        
        Task {
            do {
                let result = try await AppwriteManager.shared.databases.listDocuments(
                    databaseId: AppwriteManager.shared.databaseId,
                    collectionId: "users",
                    queries: [
                        Query.equal("userUID", value: userUID),
                        Query.limit(1)
                    ],
                    nestedType: User.self
                )
                
                if let doc = result.documents.first {
                    completion(doc.data.username)
                } else {
                    completion("Unknown User")
                }
            } catch {
                completion("Unknown User")
            }
        }
    }
}


