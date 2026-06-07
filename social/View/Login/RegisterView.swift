//
//  RegisterView.swift
//  social
//

import SwiftUI
import Appwrite
import PhotosUI

//MARK: Register View
struct RegisterView: View{
    //MARK: User Details
    @State var emailID: String = ""
    @State var password: String = ""
    @State var userName: String = ""
    @State var userBio: String = ""
    @State var userBioLink: String = ""
    @State var userProfilePicData: Data?
    //MARK: View Properties
    @Environment (\.dismiss) var dismiss
    @State var showImagePicker: Bool = false
    @State var photoItem: PhotosPickerItem?
    @State var showError: Bool = false
    @State var errorMessage: String = ""
    @State var isLoading: Bool = false
    //MARK: UserDefaults
    @AppStorage("log_status") var logStatus: Bool = false
    @AppStorage("user_profile_url") var profileURL: URL?
    @AppStorage("user_name") var userNameStored: String = ""
    @AppStorage("user_UID") var userUID: String = ""
    var body: some View{
        VStack(spacing: 10){
            Text("Let's Register")
                .font(.largeTitle.bold())
                .hAlign(.leading)
            
            Text("Hello user, have a wonderful journey")
                .font(.title3)
                .hAlign(.leading)
            
            //MARK: For smaller size Optimization
            ViewThatFits{
                ScrollView(.vertical, showsIndicators: false){
                    HelperView()
                }
                
                HelperView()
            }
            
            //MARK: Register Button
            HStack{
                Text("Already have an account?")
                    .foregroundColor(.gray)
                
                Button("Login Now"){
                    dismiss()
                }
                .fontWeight(.bold)
                .foregroundColor(.blue)
            }
            .font(.callout)
            .vAlign(.bottom)
        }
            .vAlign(.top)
            .padding(15)
            .overlay(content: {
                LoadingView(show: $isLoading)
            })
            .photosPicker(isPresented: $showImagePicker, selection: $photoItem)
            .onChange(of: photoItem) { newValue in
                //MARK: Extracting UIImage From PhotoItem
                if let newValue{
                    Task{
                        do{
                            guard let imageData = try await newValue.loadTransferable(type: Data.self) else{return}
                            //MARK: UI Must be Updated on Main Thread
                            await MainActor.run(body: {
                                userProfilePicData = imageData
                            })
                            
                        }catch{
                            
                        }
                    }
                }
            }
            //MARK: Displaying Alert
            .alert(errorMessage, isPresented: $showError, actions: {})
    }
    
    @ViewBuilder
    func HelperView()->some View{
        VStack(spacing: 12){
            ZStack{
                if let userProfilePicData, let image = UIImage(data: userProfilePicData){
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }else{
                    Image("NullProfile")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
            }
            .frame(width: 85, height: 85)
            .clipShape(Circle())
            .contentShape(Circle())
            .onTapGesture {
                showImagePicker.toggle()
            }
            .padding(.top,25)
            
            TextField("Username", text: $userName)
                .textContentType(.emailAddress)
                .border(1, .gray.opacity(0.5))  //Border Size
            
            TextField("Email", text: $emailID)
                .textContentType(.emailAddress)
                .border(1, .gray.opacity(0.5))  //Border Size
            
            SecureField("Password", text: $password)
                .textContentType(.password)
                .border(1, .gray.opacity(0.5))  //Border Size
            
            TextField("About You", text: $userBio,axis: .vertical)
                .frame(minHeight: 100, alignment: .top)
                .textContentType(.emailAddress)
                .border(1, .gray.opacity(0.5))  //Border Size
            
            TextField("Bio Link (Optional)", text: $userBioLink)
                .textContentType(.emailAddress)
                .border(1, .gray.opacity(0.5))  //Border Size
            
            Button(action: registerUser){
                //MARK: Login Button
                Text("Sign Up")
                    .foregroundColor(.white)
                    .hAlign(.center)
                    .fillView(.blue) // Sign In button color
            }
            .disableWithOpacity(userName == "" || userBio == "" || emailID == "" || password == "" || userProfilePicData == nil)
            .padding(.top,10)
        }
    }
    
    func registerUser(){
        isLoading = true
        closeKeyboard()
        Task{
            do{
                //Step 1: Creating Appwrite Account
                let uniqueID = ID.unique()
                let user = try await AppwriteManager.shared.account.create(
                    userId: uniqueID,
                    email: emailID,
                    password: password,
                    name: userName
                )
                let userUID = user.id
                
                //Step 2: Log in immediately to establish a session for uploads/writes
                _ = try await AppwriteManager.shared.account.createEmailPasswordSession(
                    email: emailID,
                    password: password
                )
                
                //Step 3: Uploading Profile Photo into Appwrite Storage
                guard let imageData = userProfilePicData else{return}
                let fileId = "profile_\(userUID)"
                let inputFile = InputFile.fromData(imageData, filename: "profile.jpg", mimeType: "image/jpeg")
                
                let file = try await AppwriteManager.shared.storage.createFile(
                    bucketId: AppwriteManager.shared.bucketId,
                    fileId: fileId,
                    file: inputFile
                )
                
                //Step 4: Get Photo URL
                let downloadURLString = AppwriteManager.shared.storage.getFileView(
                    bucketId: AppwriteManager.shared.bucketId,
                    fileId: file.id
                ).absoluteString
                
                guard let downloadURL = URL(string: downloadURLString) else { return }
                
                //Step 5: Creating a User Object
                let userObj = User(username: userName, userBio: userBio, userBioLink: userBioLink, userUID: userUID, userEmail: emailID, userProfileURL: downloadURL)
                
                //Step 6: Storing User Data into Database
                _ = try await AppwriteManager.shared.databases.createDocument(
                    databaseId: AppwriteManager.shared.databaseId,
                    collectionId: AppwriteManager.shared.usersCollectionId,
                    documentId: userUID,
                    data: userObj.toDictionary
                )
                
                //MARK: Print saved successfully
                print("Saved Successfully")
                await MainActor.run(body: {
                    userNameStored = userName
                    self.userUID = userUID
                    profileURL = downloadURL
                    logStatus = true
                    isLoading = false
                })
            }catch{
                // Clean up session context on failure
                try? await AppwriteManager.shared.account.deleteSession(sessionId: "current")
                await setError(error)
            }
        }
    }
    func setError(_ error: Error)async{
        //MARK: UI Must be Update on Main Thread
        await MainActor.run(body: {
            errorMessage = error.localizedDescription
            showError.toggle()
            isLoading = false
        })
    }
}

struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
