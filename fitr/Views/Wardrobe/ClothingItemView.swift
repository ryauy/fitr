//
//  ClothingItemView.swift
//  fitr
//
//  Created by Ryan Nguyen on 3/29/25.
//

import SwiftUI
import Kingfisher

struct ClothingItemView: View {
    let item: ClothingItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            KFImage(URL(string: item.imageURL))
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 180)
                .cornerRadius(12, corners: [.topLeft, .topRight])
                .clipped()
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                    .foregroundColor(AppColors.davyGrey)
                    .lineLimit(1)
                
                Text(item.type.rawValue)
                    .font(.subheadline)
                    .foregroundColor(AppColors.davyGrey.opacity(0.8))
                
                HStack {
                    Circle()
                        .fill(Color(hex: item.color))
                        .frame(width: 12, height: 12)
                    
                    Text(item.color)
                        .font(.caption)
                        .foregroundColor(AppColors.davyGrey.opacity(0.7))
                        .lineLimit(1)
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(Array(item.weatherTags), id: \.self) { tag in
                            Text(tag.rawValue)
                                .font(.system(size: 10))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(AppColors.lightPink.opacity(0.3))
                                .foregroundColor(AppColors.davyGrey)
                                .cornerRadius(10)
                        }
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 10)
        }
        .background(AppColors.moonMist.opacity(0.2))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}
