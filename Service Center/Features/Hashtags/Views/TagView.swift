//
//  TagView.swift
//  Service Center
//
//  Created by Kevin on 2/13/25.
//


import SwiftUI


struct TagView: View {
    let tag: String
    let color: Color
    let icon: String
    let onRemove: () -> Void
    var body: some View {
        HStack(spacing: 10) {
            Text(tag)
                .font(.callout)
                .fontWeight(.semibold)
            
            Image(systemName: icon)
                .onTapGesture {
                    onRemove()
                }
        }
        .frame(height: 35)
        .foregroundStyle(.white)
        .padding(.horizontal, 15)
        .background {
            Capsule()
                .fill(color)
        }
    }
    
}
