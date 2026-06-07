//
//  CarListingCardView.swift
//  social
//
//  Created by Naveen on 26/06/24.
//

import SwiftUI

struct CarListingCardView: View {
    var carListing: CarListing
    var showAsList: Bool = false
    
    private let priceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image container
            if let firstImageUrl = carListing.imageURLs.first {
                AsyncImage(url: firstImageUrl) { image in
                    image.resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: showAsList ? 140 : 160)
                        .clipped()
                } placeholder: {
                    ZStack {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                        
                        ProgressView()
                    }
                    .frame(height: showAsList ? 140 : 160)
                }
            }
            
            // Badge for condition
            HStack {
                Spacer()
                Text(carListing.condition)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(conditionColor(carListing.condition))
                    )
            }
            .padding(.horizontal, 8)
            .padding(.top, -24)
            .zIndex(1)
            
            
            // Content Area
            VStack(alignment: .leading, spacing: 6) { // Reduced spacing
                // Title and year
                if showAsList {
                    // List view layout - more horizontal space
                    HStack {
                        Text("\(formatYear(carListing.year)) \(carListing.make)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text(priceFormatter.string(from: NSNumber(value: carListing.price)) ?? "$0.00")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                } else {
                    // Grid view layout - stack vertically for narrow cards
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(carListing.year) \(carListing.make)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .lineLimit(1)
                        
                        Text(priceFormatter.string(from: NSNumber(value: carListing.price)) ?? "$0.00")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                            .lineLimit(1)
                    }
                }
                
                Text(carListing.model)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                // Specs row
                HStack {
                    specIcon(iconName: "speedometer", text: "\(formatMileage(carListing.mileage))")
                    Spacer()
                    
                    specIcon(iconName: "fuelpump.fill", text: carListing.fuelType)
                    Spacer()
                    
                    specIcon(iconName: "gearshape.fill", text: carListing.transmission)
                }
                .padding(.top, 2)
                
                // Location with small text
                HStack {
                    Image(systemName: "location.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    
                    Text(carListing.location)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                .padding(.top, 2)
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)
            .padding(.bottom, 14)
            .background(Color(.systemBackground))
        }
        .frame(maxWidth: .infinity) // Make sure the card fills available width
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
    }
    
    private func formatYear(_ year: Int) -> String {
        return "\(year)" // Convert to string without formatting
    }
    
    // Helper methods (unchanged)
    private func formatMileage(_ mileage: Int) -> String {
        if mileage >= 1000 {
            let formattedMileage = Double(mileage) / 1000.0
            return String(format: "%.1fk", formattedMileage)
        }
        return "\(mileage)"
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
    
    private func specIcon(iconName: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1) // Ensure text truncates
        }
    }
}
