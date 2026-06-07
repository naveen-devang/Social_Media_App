import SwiftUI

struct CarListingDetailsView: View {
    var carListing: CarListing
    @State private var currentImageIndex: Int = 0
    @State private var showContactSheet: Bool = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Image Gallery
                imageGallery
                
                // Car details sections
                detailsContent
            }
            .padding(.bottom, 80) // Add padding for the bottom action bar
        }
        .navigationTitle("Vehicle Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    // Share functionality
                }) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .overlay(alignment: .bottom) {
            contactFooterView
        }
        .sheet(isPresented: $showContactSheet) {
            contactDetailsSheet
        }
    }
    
    // MARK: - Component Views
    
    // Image Gallery
    private var imageGallery: some View {
        VStack(spacing: 8) {
            TabView(selection: $currentImageIndex) {
                ForEach(Array(carListing.imageURLs.enumerated()), id: \.element) { index, url in
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .frame(height: 250)
                            .background(Color.gray.opacity(0.1))
                    }
                    .tag(index)
                }
            }
            .frame(height: 250)
            .tabViewStyle(PageTabViewStyle())
            .cornerRadius(0)
            
            // Image counter
            if carListing.imageURLs.count > 1 {
                HStack {
                    Spacer()
                    Text("\(currentImageIndex + 1) / \(carListing.imageURLs.count)")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(16)
                }
                .padding(.horizontal, 16)
                .padding(.top, -40)
            }
        }
    }
    
    // Main Details Content
    private var detailsContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Price and Title
            priceTitleSection
            
            // Key specs (mileage, fuel, transmission)
            keySpecsSection
            
            Divider()
            
            // Vehicle Specifications
            specificationsSection
            
            Divider()
            
            // Description
            descriptionSection
            
            // Features
            if !carListing.features.isEmpty {
                Divider()
                featuresSection
            }
            
            Divider()
            
            // Seller Information
            sellerSection
        }
        .padding(.horizontal, 16)
    }
    
    // Price and Title Section
    private var priceTitleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("$\(carListing.price, specifier: "%.0f")")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)
            
            Text("\(carListing.year) \(carListing.make) \(carListing.model)")
                .font(.title3)
                .fontWeight(.semibold)
            
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(.secondary)
                    .font(.caption)
                
                Text(carListing.location)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // Key Specs Section
    private var keySpecsSection: some View {
        HStack(spacing: 0) {
            VStack(spacing: 6) {
                Image(systemName: "speedometer")
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
                
                Text("\(carListing.mileage)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("Miles")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            
            Divider()
                .frame(height: 40)
            
            VStack(spacing: 6) {
                Image(systemName: "fuelpump.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
                
                Text(carListing.fuelType)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("Fuel")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            
            Divider()
                .frame(height: 40)
            
            VStack(spacing: 6) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
                
                Text(carListing.transmission)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("Transmission")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // Specifications Section
    private var specificationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Vehicle Specifications")
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                specItem(title: "Make", value: carListing.make)
                specItem(title: "Model", value: carListing.model)
                specItem(title: "Trim", value: carListing.trim)
                specItem(title: "Year", value: String(carListing.year))
            }
            
            // VIN Number in full-width row
            specItem(title: "VIN Number", value: carListing.vinNumber)
                .gridCellColumns(2)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                specItem(title: "Body Type", value: carListing.bodyType)
                specItem(title: "Exterior Color", value: carListing.exteriorColor)
                specItem(title: "Interior Color", value: carListing.interiorColor)
                specItem(title: "Engine", value: carListing.engine)
                specItem(title: "Drivetrain", value: carListing.drivetrain)
                specItem(title: "Transmission", value: carListing.transmission)
                specItem(title: "Fuel Type", value: carListing.fuelType)
                specItem(title: "Condition", value: carListing.condition)
                specItem(title: "Mileage", value: "\(carListing.mileage) miles")
                specItem(title: "Seller Type", value: carListing.sellerType)
            }
        }
    }
    // Description Section
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Description")
            
            Text(carListing.description)
                .font(.body)
                .foregroundColor(.secondary)
                .lineSpacing(4)
        }
    }
    
    // Features Section
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Features")
            
            ForEach(carListing.features.components(separatedBy: ", "), id: \.self) { feature in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 16))
                    
                    Text(feature)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding(.vertical, 2)
            }
        }
    }
    
    // Seller Information Section
    private var sellerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Seller Information")
            
            HStack(spacing: 16) {
                AsyncImage(url: carListing.sellerProfileURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 60, height: 60)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(carListing.sellerName)
                        .font(.headline)
                    
                    Text("Joined \(formattedDate())")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    // View seller profile
                }) {
                    Text("View Profile")
                        .font(.footnote)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .padding(16)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // Individual Specification Item
    private func specItem(title: String, value: String) -> some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value.isEmpty ? "N/A" : value)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    // Section Header
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .fontWeight(.bold)
    }
    
    // Contact Footer
    private var contactFooterView: some View {
        HStack(spacing: 16) {
            Button(action: {
                // Action to message seller
                NotificationCenter.default.post(
                    name: NSNotification.Name("OpenMessageView"),
                    object: nil,
                    userInfo: ["sellerUID": carListing.sellerUID]
                )
            }) {
                HStack {
                    Image(systemName: "message.fill")
                    Text("Message")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(Color.blue.opacity(0.8))
                .cornerRadius(12)
            }
            
            Button(action: {
                showContactSheet = true
            }) {
                HStack {
                    Image(systemName: "phone.fill")
                    Text("Call")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .cornerRadius(12)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Rectangle()
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: -4)
        )
    }
    
    // Contact Sheet
    private var contactDetailsSheet: some View {
        VStack(spacing: 20) {
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, 8)
            
            Text("Contact Seller")
                .font(.title3)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 20) {
                contactDetailButton(
                    icon: "phone.fill",
                    title: "Phone Number",
                    value: carListing.contactNumber.isEmpty ? "No phone number provided" : carListing.contactNumber,
                    action: {
                        if !carListing.contactNumber.isEmpty {
                            let phoneNumber = carListing.contactNumber.replacingOccurrences(of: " ", with: "")
                            let phoneUrl = URL(string: "tel://\(phoneNumber)")
                            if let url = phoneUrl {
                                openURL(url)
                            }
                        }
                    }
                )
                
                contactDetailButton(
                    icon: "envelope.fill",
                    title: "Email",
                    value: "Contact via message",
                    action: {
                        NotificationCenter.default.post(
                            name: NSNotification.Name("OpenMessageView"),
                            object: nil,
                            userInfo: ["sellerUID": carListing.sellerUID]
                        )
                        showContactSheet = false
                    }
                )
                
                contactDetailButton(
                    icon: "location.fill",
                    title: "Location",
                    value: carListing.location,
                    action: {
                        if !carListing.location.isEmpty {
                            let mapQuery = carListing.location.replacingOccurrences(of: " ", with: "+")
                            if let url = URL(string: "maps://?q=\(mapQuery)") {
                                openURL(url)
                            }
                        }
                    }
                )
            }
            .padding(.top, 8)
            
            Button(action: {
                showContactSheet = false
            }) {
                Text("Close")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.top, 24)
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }
    
    // Contact Detail Button
    private func contactDetailButton(icon: String, title: String, value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(.blue)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(value)
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // MARK: - Methods
                
                // Mock joined date formatter
                private func formattedDate() -> String {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "MMM yyyy"
                    return dateFormatter.string(from: Date())
                }
            }

            // MARK: - Sharing Functionality
            struct ShareSheet: UIViewControllerRepresentable {
                var items: [Any]
                
                func makeUIViewController(context: Context) -> UIActivityViewController {
                    let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
                    return controller
                }
                
                func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
            }
