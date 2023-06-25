//
//  socialApp.swift
//  social
//
//  Created by デバン・ナビーン on 21/06/23.
//

import SwiftUI
import Firebase

@main
struct socialApp: App {
    init(){
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
