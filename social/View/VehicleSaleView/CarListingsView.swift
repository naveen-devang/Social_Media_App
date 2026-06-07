//
//  CarListingsView.swift
//  social
//
//  Created by Naveen on 26/06/24.
//
import SwiftUI



struct CarListingsView: View {
    @Binding var carListings: [CarListing]
    @State private var isFetching: Bool = true
    @State private var lastDocument: DocumentSnapshot? = nil
    @State private var isFetchingMore: Bool = false
    @State private var showUploadView: Bool = false
    
    // Search and filter states
    @State private var searchText = ""
    @State private var sortOption: SortOption = .newest
    @State private var showFilterSheet = false
    
    // Filter states
    @State private var selectedMakes: Set<String> = []
    
    @State private var availableMakes: [String] = []

    @State private var minPrice: Double = 0
    @State private var maxPrice: Double = 100000
    @State private var minYear: Int = 2010
    @State private var maxYear: Int = 2025
    @State private var selectedConditions: Set<String> = []
    @State private var currentPage = 0
    
    enum SortOption: String, CaseIterable {
        case newest = "Newest"
        case priceHighToLow = "Price: High to Low"
        case priceLowToHigh = "Price: Low to High"
        case yearNewest = "Year: Newest"
        case yearOldest = "Year: Oldest"
    }
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationStack {
            if #available(iOS 17.0, *) {
                VStack(spacing: 0) {
                    // Search and filter header
                    searchAndFilterBar
                    
                    // Active filters display
                    if hasActiveFilters {
                        activeFiltersRow
                    }
                    
                    if isFetching {
                        Spacer()
                        ProgressView()
                        Spacer()
                    } else if carListings.isEmpty {
                        Spacer()
                        Text("No listings found")
                            .foregroundColor(.secondary)
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(carListings, id: \.id) { listing in
                                    NavigationLink(destination: CarListingDetailsView(carListing: listing)) {
                                        CarListingCardView(carListing: listing, showAsList: true)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                            
                            // Pagination controls
                            paginationControls
                            
                            // Infinite scroll trigger
                            GeometryReader { geometry in
                                Color.clear
                                    .onAppear {
                                        let threshold: CGFloat = 100.0
                                        if geometry.frame(in: .global).maxY > UIScreen.main.bounds.height - threshold {
                                            fetchMoreCarListingsIfNeeded()
                                        }
                                    }
                            }
                            .frame(height: 1)
                            
                            if isFetchingMore {
                                ProgressView()
                                    .padding(.vertical)
                            }
                        }
                    }
                }
                .navigationTitle("Vehicle Listings")
                .toolbarTitleDisplayMode(.inlineLarge)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showUploadView.toggle()
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
                .sheet(isPresented: $showUploadView) {
                    UploadCarListingView()
                }
                .sheet(isPresented: $showFilterSheet) {
                    filterSheet
                }
                .task {
                    await fetchCarListings()
                }
            } else {
                // Fallback on earlier versions
                VStack(spacing: 0) {
                    // Search and filter header
                    searchAndFilterBar
                    
                    // Active filters display
                    if hasActiveFilters {
                        activeFiltersRow
                    }
                    
                    if isFetching {
                        Spacer()
                        ProgressView()
                        Spacer()
                    } else if carListings.isEmpty {
                        Spacer()
                        Text("No listings found")
                            .foregroundColor(.secondary)
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(carListings, id: \.id) { listing in
                                    NavigationLink(destination: CarListingDetailsView(carListing: listing)) {
                                        CarListingCardView(carListing: listing, showAsList: true)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                            
                            // Pagination controls
                            paginationControls
                            
                            // Infinite scroll trigger
                            GeometryReader { geometry in
                                Color.clear
                                    .onAppear {
                                        let threshold: CGFloat = 100.0
                                        if geometry.frame(in: .global).maxY > UIScreen.main.bounds.height - threshold {
                                            fetchMoreCarListingsIfNeeded()
                                        }
                                    }
                            }
                            .frame(height: 1)
                            
                            if isFetchingMore {
                                ProgressView()
                                    .padding(.vertical)
                            }
                        }
                    }
                }
                .navigationTitle("Vehicle Listings")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showUploadView.toggle()
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
                .sheet(isPresented: $showUploadView) {
                    UploadCarListingView()
                }
                .sheet(isPresented: $showFilterSheet) {
                    filterSheet
                }
                .task {
                    await fetchCarListings()
                }
            }
        }
    }
    
    // MARK: - UI Components
    
    private var searchAndFilterBar: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search makes, models...", text: $searchText)
                    .onChange(of: searchText) { _ in
                        // Debounce search
                        Task {
                            await fetchCarListings()
                        }
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        Task {
                            await fetchCarListings()
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
            Button(action: {
                showFilterSheet = true
            }) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.system(size: 20))
                    .foregroundColor(hasActiveFilters ? .blue : .primary)
            }
            .padding(.leading, 8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var viewModeAndSortBar: some View {
        HStack {
            Spacer()
            
            // Sort menu
            Menu {
                ForEach(SortOption.allCases, id: \.self) { option in
                    Button(action: {
                        sortOption = option
                        Task {
                            await fetchCarListings()
                        }
                    }) {
                        HStack {
                            Text(option.rawValue)
                            if sortOption == option {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text("Sort: \(sortOption.rawValue)")
                        .font(.footnote)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10))
                }
                .foregroundColor(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    private var activeFiltersRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(selectedMakes), id: \.self) { make in
                    filterChip(text: make) {
                        selectedMakes.remove(make)
                        Task {
                            await fetchCarListings()
                        }
                    }
                }
                
                ForEach(Array(selectedConditions), id: \.self) { condition in
                    filterChip(text: condition) {
                        selectedConditions.remove(condition)
                        Task {
                            await fetchCarListings()
                        }
                    }
                }
                
                if minPrice > 0 {
                    filterChip(text: "Min: $\(Int(minPrice))") {
                        minPrice = 0
                        Task {
                            await fetchCarListings()
                        }
                    }
                }
                
                if maxPrice < 100000 {
                    filterChip(text: "Max: $\(Int(maxPrice))") {
                        maxPrice = 100000
                        Task {
                            await fetchCarListings()
                        }
                    }
                }
                
                if minYear > 2010 {
                    filterChip(text: "From: \(minYear)") {
                        minYear = 2010
                        Task {
                            await fetchCarListings()
                        }
                    }
                }
                
                if maxYear < 2025 {
                    filterChip(text: "To: \(maxYear)") {
                        maxYear = 2025
                        Task {
                            await fetchCarListings()
                        }
                    }
                }
                
                Button(action: {
                    // Clear all filters
                    selectedMakes.removeAll()
                    selectedConditions.removeAll()
                    minPrice = 0
                    maxPrice = 100000
                    minYear = 2010
                    maxYear = 2025
                    Task {
                        await fetchCarListings()
                    }
                }) {
                    Text("Clear All")
                        .font(.footnote)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .cornerRadius(16)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(Color(.systemGray6).opacity(0.5))
    }
    
    private func filterChip(text: String, action: @escaping () -> Void) -> some View {
        HStack(spacing: 4) {
            Text(text)
                .font(.footnote)
                .foregroundColor(.primary)
            
            Button(action: action) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var paginationControls: some View {
        HStack {
            Button(action: {
                if currentPage > 0 {
                    currentPage -= 1
                    Task {
                        await fetchCarListings()
                    }
                }
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(currentPage > 0 ? .blue : .gray)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            .disabled(currentPage == 0)
            
            Text("Page \(currentPage + 1)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button(action: {
                currentPage += 1
                Task {
                    await fetchCarListings()
                }
            }) {
                Image(systemName: "chevron.right")
                    .foregroundColor(.blue)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 20)
    }
    
    private var filterSheet: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Make Selection
                    filterSection(title: "Make") {
                        if availableMakes.isEmpty {
                            Text("No Vehicles available at the moment")
                                .foregroundColor(.secondary)
                                .padding()
                        } else {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                ForEach(availableMakes, id: \.self) { make in
                                    makeSelectionButton(make)
                                }
                            }
                        }
                    }
                    
                    // Price Range
                    filterSection(title: "Price Range") {
                        VStack(spacing: 16) {
                            HStack {
                                Text("$\(Int(minPrice))")
                                Spacer()
                                Text("$\(Int(maxPrice))")
                            }
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            
                            RangeSlider(
                                minValue: $minPrice,
                                maxValue: $maxPrice,
                                minLimit: 0,
                                maxLimit: 100000,
                                step: 1000
                            )
                        }
                    }
                    
                    // Year Range
                    filterSection(title: "Year") {
                        VStack(spacing: 16) {
                            HStack {
                                Text("\(minYear)")
                                Spacer()
                                Text("\(maxYear)")
                            }
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            
                            RangeSlider(
                                minValue: $minYear.double,
                                maxValue: $maxYear.double,
                                minLimit: 2010,
                                maxLimit: 2025,
                                step: 1
                            )
                        }
                    }
                    
                    // Condition
                    filterSection(title: "Condition") {
                        let conditions = ["Excellent", "Good", "Fair", "Poor"]
                        
                        HStack(spacing: 10) {
                            ForEach(conditions, id: \.self) { condition in
                                conditionButton(condition)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        selectedMakes.removeAll()
                        selectedConditions.removeAll()
                        minPrice = 0
                        maxPrice = 100000
                        minYear = 2010
                        maxYear = 2025
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        Task {
                            await fetchCarListings()
                        }
                        showFilterSheet = false
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }
    
    private func filterSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
            
            content()
        }
    }
    
    private func makeSelectionButton(_ make: String) -> some View {
        Button(action: {
            if selectedMakes.contains(make) {
                selectedMakes.remove(make)
            } else {
                selectedMakes.insert(make)
            }
        }) {
            HStack {
                Text(make)
                    .font(.subheadline)
                Spacer()
                if selectedMakes.contains(make) {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(selectedMakes.contains(make) ? Color.blue.opacity(0.1) : Color(.systemGray6))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func conditionButton(_ condition: String) -> some View {
        Button(action: {
            if selectedConditions.contains(condition) {
                selectedConditions.remove(condition)
            } else {
                selectedConditions.insert(condition)
            }
        }) {
            Text(condition)
                .font(.subheadline)
                .foregroundColor(selectedConditions.contains(condition) ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(selectedConditions.contains(condition) ? conditionColor(condition) : Color(.systemGray6))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Helper Methods
    
    private var hasActiveFilters: Bool {
        return !selectedMakes.isEmpty ||
               !selectedConditions.isEmpty ||
               minPrice > 0 ||
               maxPrice < 100000 ||
               minYear > 2010 ||
               maxYear < 2025
    }
    
    private func conditionColor(_ condition: String) -> Color {
        switch condition.lowercased() {
        case "excellent":
            return Color.green
        case "good":
            return Color.blue
        case "fair":
            return Color.orange
        case "poor":
            return Color.red
        default:
            return Color.gray
        }
    }
    
    // Inside your CarListingsView struct, replace the fetchCarListings() function with this:

    func fetchCarListings() async {
        isFetching = true
        currentPage = 0
        lastDocument = nil
        
        do {
            // Create the base query
            let db = Firestore.firestore()
            var fetchedListings: [CarListing] = []
            
            // First retrieve all listings without filters
            let collectionRef = db.collection("CarListings")
            
            // Apply sorting
            var query: Query
            switch sortOption {
            case .newest:
                query = collectionRef.order(by: "publishedDate", descending: true)
            case .priceHighToLow:
                query = collectionRef.order(by: "price", descending: true)
            case .priceLowToHigh:
                query = collectionRef.order(by: "price", descending: false)
            case .yearNewest:
                query = collectionRef.order(by: "year", descending: true)
            case .yearOldest:
                query = collectionRef.order(by: "year", descending: false)
            }
            
            // Apply limited Firestore filters - only use one compound query for performance
            // We'll apply the rest of the filters in memory
            
            // Only add price filter in Firestore query since it's likely most restrictive
            if minPrice > 0 {
                query = query.whereField("price", isGreaterThanOrEqualTo: minPrice)
            }
            
            if maxPrice < 100000 {
                query = query.whereField("price", isLessThanOrEqualTo: maxPrice)
            }
            
            // Limit to a reasonable number for in-memory filtering
            query = query.limit(to: 10)
            
            let docs = try await query.getDocuments()
            if let lastDoc = docs.documents.last {
                lastDocument = lastDoc
            }
            
            // Get all listings first
            fetchedListings = docs.documents.compactMap { doc -> CarListing? in
                try? doc.data(as: CarListing.self)
            }
            
            let makes = Set(fetchedListings.map { $0.make }).sorted()
            availableMakes = makes
            
            // Now perform all filtering in memory
            var filteredListings = fetchedListings
            
            // Filter by make if selected
            if !selectedMakes.isEmpty {
                filteredListings = filteredListings.filter { listing in
                    selectedMakes.contains(listing.make)
                }
            }
            
            // Filter by condition if selected
            if !selectedConditions.isEmpty {
                filteredListings = filteredListings.filter { listing in
                    selectedConditions.contains(listing.condition)
                }
            }
            
            // Filter by year
            if minYear > 2010 || maxYear < 2025 {
                filteredListings = filteredListings.filter { listing in
                    listing.year >= minYear && listing.year <= maxYear
                }
            }
            
            // Filter by search text (more flexible search)
            if !searchText.isEmpty {
                filteredListings = filteredListings.filter { listing in
                    let searchLower = searchText.lowercased()
                    return listing.make.lowercased().contains(searchLower) ||
                           listing.model.lowercased().contains(searchLower) ||
                           "\(listing.year)".contains(searchLower)
                }
            }
            
            // Update the UI with filtered results
            carListings = filteredListings
            isFetching = false
        } catch {
            print("Error fetching car listings: \(error.localizedDescription)")
            isFetching = false
        }
    }
    
    // You should also update the fetchMoreCarListingsIfNeeded function with similar logic
    func fetchMoreCarListingsIfNeeded() {
        guard let lastDocument = lastDocument, !isFetchingMore else { return }
        isFetchingMore = true
        
        Task {
            do {
                let db = Firestore.firestore()
                
                // Create base query with sorting
                let collectionRef = db.collection("CarListings")
                
                // Apply sorting
                var query: Query
                switch sortOption {
                case .newest:
                    query = collectionRef.order(by: "publishedDate", descending: true)
                case .priceHighToLow:
                    query = collectionRef.order(by: "price", descending: true)
                case .priceLowToHigh:
                    query = collectionRef.order(by: "price", descending: false)
                case .yearNewest:
                    query = collectionRef.order(by: "year", descending: true)
                case .yearOldest:
                    query = collectionRef.order(by: "year", descending: false)
                }
                
                // Start after last document
                query = query.start(afterDocument: lastDocument)
                
                // Apply limited Firestore filters
                if minPrice > 0 {
                    query = query.whereField("price", isGreaterThanOrEqualTo: minPrice)
                }
                
                if maxPrice < 100000 {
                    query = query.whereField("price", isLessThanOrEqualTo: maxPrice)
                }
                
                // Limit query results
                query = query.limit(to: 50)
                
                let docs = try await query.getDocuments()
                if let lastDoc = docs.documents.last {
                    self.lastDocument = lastDoc
                }
                
                // Get all new listings
                var fetchedListings = docs.documents.compactMap { doc -> CarListing? in
                    try? doc.data(as: CarListing.self)
                }
                
                // Apply filters in memory
                if !selectedMakes.isEmpty {
                    fetchedListings = fetchedListings.filter { listing in
                        selectedMakes.contains(listing.make)
                    }
                }
                
                if !selectedConditions.isEmpty {
                    fetchedListings = fetchedListings.filter { listing in
                        selectedConditions.contains(listing.condition)
                    }
                }
                
                // Filter by year
                if minYear > 2010 || maxYear < 2025 {
                    fetchedListings = fetchedListings.filter { listing in
                        listing.year >= minYear && listing.year <= maxYear
                    }
                }
                
                // Filter by search text
                if !searchText.isEmpty {
                    fetchedListings = fetchedListings.filter { listing in
                        let searchLower = searchText.lowercased()
                        return listing.make.lowercased().contains(searchLower) ||
                               listing.model.lowercased().contains(searchLower) ||
                               "\(listing.year)".contains(searchLower)
                    }
                }
                
                // Update the UI
                carListings.append(contentsOf: fetchedListings)
                isFetchingMore = false
            } catch {
                print("Error fetching more car listings: \(error.localizedDescription)")
                isFetchingMore = false
            }
        }
    }
}

// MARK: - Extensions

// Extension to allow Double binding for Int properties
extension Int {
    var double: Double {
        get { Double(self) }
        set { self = Int(newValue) }
    }
}

// MARK: - RangeSlider Component
struct RangeSlider: View {
    @Binding var minValue: Double
    @Binding var maxValue: Double
    let minLimit: Double
    let maxLimit: Double
    let step: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 4)
                
                // Selected Range
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: CGFloat((maxValue - minValue) / (maxLimit - minLimit)) * geometry.size.width,
                           height: 4)
                    .offset(x: CGFloat((minValue - minLimit) / (maxLimit - minLimit)) * geometry.size.width)
                
                // Min Thumb
                Circle()
                    .fill(Color.white)
                    .frame(width: 24, height: 24)
                    .shadow(radius: 2)
                    .offset(x: CGFloat((minValue - minLimit) / (maxLimit - minLimit)) * geometry.size.width - 12)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let newValue = minLimit + Double(value.location.x / geometry.size.width) * (maxLimit - minLimit)
                                minValue = min(max(newValue, minLimit), maxValue - step)
                                // Round to nearest step
                                minValue = round(minValue / step) * step
                            }
                    )
                
                // Max Thumb
                Circle()
                    .fill(Color.white)
                    .frame(width: 24, height: 24)
                    .shadow(radius: 2)
                    .offset(x: CGFloat((maxValue - minLimit) / (maxLimit - minLimit)) * geometry.size.width - 12)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let newValue = minLimit + Double(value.location.x / geometry.size.width) * (maxLimit - minLimit)
                                maxValue = max(min(newValue, maxLimit), minValue + step)
                                // Round to nearest step
                                maxValue = round(maxValue / step) * step
                            }
                    )
            }
        }
        .frame(height: 24)
    }
}
