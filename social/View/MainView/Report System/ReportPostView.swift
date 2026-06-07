//
//  ReportPostView.swift
//  social
//
//  Created by Naveen Devang on 11/22/24.
//

import SwiftUI
import Appwrite

struct ReportPostView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: Report.ReportCategory = .harassment
    @State private var reason: String = ""
    @State private var isSubmitting = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    let post: Post
    let userUID: String
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Category")) {
                    Picker("Select Category", selection: $selectedCategory) {
                        ForEach(Report.ReportCategory.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                }
                
                Section(header: Text("Additional Details")) {
                    TextEditor(text: $reason)
                        .frame(height: 100)
                        .overlay(
                            Group {
                                if reason.isEmpty {
                                    Text("Please provide more details about your report...")
                                        .foregroundColor(.gray)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 8)
                                }
                            },
                            alignment: .topLeading
                        )
                }
                
                Section {
                    Button(action: submitReport) {
                        if isSubmitting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Submit Report")
                        }
                    }
                    .disabled(reason.isEmpty || isSubmitting)
                }
            }
            .navigationTitle("Report Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Report Status", isPresented: $showAlert) {
                Button("OK") {
                    if alertMessage.contains("submitted") {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func submitReport() {
        isSubmitting = true
        
        let report = Report(
            id: nil,
            postID: post.id ?? "",
            reporterUID: userUID,
            reportedUserUID: post.userUID,
            reason: reason,
            category: selectedCategory.rawValue,
            timestamp: Date(),
            status: "pending"
        )
        
        Task {
            do {
                _ = try await AppwriteManager.shared.databases.createDocument(
                    databaseId: AppwriteManager.shared.databaseId,
                    collectionId: "reports",
                    documentId: ID.unique(),
                    data: report.toDictionary
                )
                
                await MainActor.run {
                    isSubmitting = false
                    alertMessage = "Report submitted successfully"
                    showAlert = true
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    alertMessage = "Error submitting report: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
}
