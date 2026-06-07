//
//  EditHistoryView.swift
//  social
//
//  Created by Naveen Devang on 12/1/24.
//

import SwiftUI


struct EditHistoryView: View {
    let vehicleID: String
    @State private var editHistory: [VehicleEdit] = []
    @State private var isLoading = true
    @State private var lastDocument: DocumentSnapshot?
    @State private var hasMoreData = true
    @State private var selectedEdit: VehicleEdit?
    @State private var showDetailView = false
    @State private var isSheetLoading = false
    
    private let pageSize = 10
    
    var body: some View {
        ZStack {
            // Background
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Edit History")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Menu {
                        Button(action: {
                            // Reset and reload
                            editHistory = []
                            lastDocument = nil
                            hasMoreData = true
                            fetchEditHistory()
                        }) {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                            .foregroundColor(.primary)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
                
                if editHistory.isEmpty && isLoading {
                    // Loading state
                    VStack {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading edit history...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.top, 16)
                        Spacer()
                    }
                } else if editHistory.isEmpty {
                    // Empty state
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("No edit history found")
                            .font(.headline)
                        Text("Any changes made to this vehicle will appear here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        Spacer()
                    }
                } else {
                    // Content
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(editHistory) { edit in
                                EditHistoryCard(edit: edit)
                                    .onTapGesture {
                                        isSheetLoading = true
                                        selectedEdit = edit
                                        showDetailView = true
                                    }
                            }
                            
                            if hasMoreData {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                    Spacer()
                                }
                                .padding()
                                .onAppear {
                                    loadMoreContent()
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                    }
                }
            }
            
            // Global loading indicator
            if isLoading && !editHistory.isEmpty {
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                    .overlay(
                        ProgressView()
                            .scaleEffect(1.5)
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(10)
                            .shadow(radius: 10)
                    )
            }
        }
        .sheet(isPresented: $showDetailView, onDismiss: {
            isSheetLoading = false
        }) {
            if let edit = selectedEdit {
                EditDetailView(edit: edit, isLoading: $isSheetLoading)
            }
        }
        .onAppear {
            if editHistory.isEmpty {
                fetchEditHistory()
            }
        }
    }
    
    private func fetchEditHistory() {
        isLoading = true
        
        let db = Firestore.firestore()
        var query = db.collection("Vehicles")
            .document(vehicleID)
            .collection("EditHistory")
            .order(by: "timestamp", descending: true)
            .limit(to: pageSize)
        
        if let lastDoc = lastDocument {
            query = query.start(afterDocument: lastDoc)
        }
        
        query.getDocuments { snapshot, error in
            isLoading = false
            
            if let error = error {
                print("Error fetching edit history: \(error.localizedDescription)")
                return
            }
            
            guard let snapshot = snapshot else { return }
            
            let newEdits = snapshot.documents.compactMap { document in
                try? document.data(as: VehicleEdit.self)
            }
            
            editHistory.append(contentsOf: newEdits)
            lastDocument = snapshot.documents.last
            hasMoreData = !snapshot.documents.isEmpty && snapshot.documents.count == pageSize
        }
    }
    
    private func loadMoreContent() {
        guard !isLoading && hasMoreData else { return }
        isLoading = true
        fetchEditHistory()
    }
}

// MARK: - Helper Views

struct EditHistoryCard: View {
    let edit: VehicleEdit
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Text(String(edit.editorName.prefix(1)).uppercased())
                                .font(.headline)
                                .foregroundColor(.white)
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("@" + edit.editorName)
                            .font(.headline)
                        
                        Text(formatTimestamp(edit.timestamp))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Text("\(edit.editedFields.count) change\(edit.editedFields.count > 1 ? "s" : "")")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            // Preview of changes
            VStack(alignment: .leading, spacing: 6) {
                if !edit.editedFields.isEmpty {
                    // Show first change + count of others
                    let firstField = edit.editedFields.first!
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(firstField.fieldName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            HStack(alignment: .top, spacing: 8) {
                                Text(firstField.previousValue)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.red.opacity(0.1))
                                    .foregroundColor(.red)
                                    .cornerRadius(4)
                                
                                Image(systemName: "arrow.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text(firstField.newValue)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.green.opacity(0.1))
                                    .foregroundColor(.green)
                                    .cornerRadius(4)
                            }
                        }
                        
                        Spacer()
                    }
                    
                    if edit.editedFields.count > 1 {
                        Text("+ \(edit.editedFields.count - 1) more \(edit.editedFields.count - 1 > 1 ? "changes" : "change")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func formatTimestamp(_ timestamp: Timestamp) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp.dateValue())
    }
}

struct EditDetailView: View {
    let edit: VehicleEdit
    @Binding var isLoading: Bool
    @Environment(\.presentationMode) var presentationMode
    @State private var loadingComplete = false
    
    var body: some View {
        NavigationView {
            ZStack {
                if !loadingComplete {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading details...")
                            .font(.headline)
                            .padding(.top)
                    }
                } else {
                    List {
                        Section {
                            HStack {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 48, height: 48)
                                    .overlay(
                                        Text(String(edit.editorName.prefix(1)).uppercased())
                                            .font(.title2)
                                            .foregroundColor(.white)
                                    )
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("@" + edit.editorName)
                                        .font(.headline)
                                    
                                    Text(formatTimestamp(edit.timestamp))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.leading, 8)
                            }
                            .padding(.vertical, 8)
                        }
                        
                        Section(header: Text("Modified Fields")) {
                            ForEach(edit.editedFields, id: \.self) { field in
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(field.fieldName)
                                        .font(.headline)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Previous Value")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        Text(field.previousValue)
                                            .font(.body)
                                            .padding(10)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .background(Color.red.opacity(0.1))
                                            .foregroundColor(.red)
                                            .cornerRadius(8)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("New Value")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        Text(field.newValue)
                                            .font(.body)
                                            .padding(10)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .background(Color.green.opacity(0.1))
                                            .foregroundColor(.green)
                                            .cornerRadius(8)
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle("Edit Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .onAppear {
                // Simulate loading to ensure sheet is properly initialized
                // This helps prevent cases where sheet content might not display
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    loadingComplete = true
                    isLoading = false
                }
            }
        }
    }
    
    private func formatTimestamp(_ timestamp: Timestamp) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp.dateValue())
    }
}
