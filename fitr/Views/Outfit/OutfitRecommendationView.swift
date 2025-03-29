//
//  OutfitRecommendationView.swift
//  fitr
//
//  Created by Ryan Nguyen on 3/29/25.
//

import SwiftUI
import Kingfisher

struct OutfitRecommendationView: View {
    let outfit: Outfit
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Today's Outfit")
                .font(.headline)
                .foregroundColor(AppColors.davyGrey)
            
            Text(outfit.description)
                .font(.subheadline)
                .foregroundColor(AppColors.davyGrey.opacity(0.8))
                .multilineTextAlignment(.leading)
                .padding(.bottom, 5)
            
            if outfit.items.isEmpty {
                Text("No items available for recommendation")
                    .font(.subheadline)
                    .foregroundColor(AppColors.davyGrey.opacity(0.6))
                    .padding()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(outfit.items) { item in
                            VStack(spacing: 8) {
                                KFImage(URL(string: item.imageURL))
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 120, height: 150)
                                    .cornerRadius(10)
                                
                                Text(item.name)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(AppColors.davyGrey)
                                    .lineLimit(1)
                                
                                Text(item.type.rawValue)
                                    .font(.caption)
                                    .foregroundColor(AppColors.davyGrey.opacity(0.7))
                            }
                            .frame(width: 120)
                        }
                    }
                    .padding(.vertical, 5)
                }
            }
        }
        .padding()
        .background(AppColors.lightPink.opacity(0.15))
        .cornerRadius(15)
    }
}
