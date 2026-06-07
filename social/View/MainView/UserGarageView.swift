//
//  UserGarageView.swift
//  social
//
//  Created by デバン・ナビーン on 22/03/24.
//

import SwiftUI

import SDWebImageSwiftUI // Import SDWebImageSwiftUI for image loading

struct UserGarageView: View {
    let userUID: String
    
    var body: some View {
        GarageView(userUID: userUID, showAddButton: false)
    }
}


