//
//  Color+Adaptive.swift
//  social
//
//  Created by デバン・ナビーン on 14/04/24.
//

import SwiftUI

extension Color {
    static var adaptiveWhite: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? .white : .black
        })
    }
}
