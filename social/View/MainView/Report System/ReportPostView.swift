//
//  ReportPostView.swift
//  social
//
//  Created by Naveen Devang on 11/22/24.
//

import SwiftUI


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
        
        let db = Firestore.firestore()
        do {
            try db.collection("Reports").addDocument(from: report) { error in
                isSubmitting = false
                
                if let error = error {
                    alertMessage = "Error submitting report: \(error.localizedDescription)"
                } else {
                    alertMessage = "Report submitted successfully"
                }
                showAlert = true
            }
        } catch {
            isSubmitting = false
            alertMessage = "Error creating report: \(error.localizedDescription)"
            showAlert = true
        }
    }
}
