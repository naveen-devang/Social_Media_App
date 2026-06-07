//
//  SearchUserView.swift
//  social
//

import SwiftUI
import Appwrite

struct SearchUserView: View {
    /// - View Properties
    @State private var fetchedUsers: [User] = []
    @State private var searchText: String = ""
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        List{
            ForEach(fetchedUsers){ user in
                NavigationLink {
                    ReuseableProfileContent(user: user)
                } label: {
                    Text(user.username)
                        .font(.callout)
                        .hAlign(.leading)
                }
            }
        }
        .listStyle(.plain)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Search Users")
        .searchable(text: $searchText)
        .onSubmit(of: .search, {
            /// - Fetch User From Appwrite
            Task{await searchUser()}
        })
        .onChange(of: searchText, perform: { newValue in
            if newValue.isEmpty{
                fetchedUsers = []
            }
        })
    }
    
    func searchUser()async{
        do{
            let result = try await AppwriteManager.shared.databases.listDocuments(
                databaseId: AppwriteManager.shared.databaseId,
                collectionId: AppwriteManager.shared.usersCollectionId,
                queries: [
                    Query.startsWith("username", searchText)
                ],
                nestedType: User.self
            )
            
            let users = result.documents.map { doc -> User in
                var u = doc.data
                u.id = doc.id
                return u
            }
            
            /// - UI Must Be Updated on Main Thread
            await MainActor.run(body: {
                fetchedUsers = users
            })
            
        } catch {
            print(error.localizedDescription)
        }
    }
}

struct SearchUserView_Previews: PreviewProvider {
    static var previews: some View {
        SearchUserView()
    }
}
