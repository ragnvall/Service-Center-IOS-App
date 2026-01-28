//
//  Extensions.swift
//  Service Center
//
//  Created by Robert Agnvall on 1/18/25.
//

import Foundation
import SwiftUI

extension View {
    func roundedCorner(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}


extension Int {
    func formattedString() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        
        let thousand = 1000
        let million = thousand * thousand
        
        if self >= million {
            let formattedNumber = Double(self) / Double(million)
            return "\(formatter.string(from: NSNumber(value: formattedNumber)) ?? "")M"
        } else if self >= thousand {
            let formattedNumber = Double(self) / Double(thousand)
            return "\(formatter.string(from: NSNumber(value: formattedNumber)) ?? "")K"
        } else {
            return "\(self)"
        }
    }
}
