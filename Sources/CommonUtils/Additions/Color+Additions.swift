//
//  File.swift
//  
//
//  Created by Ilya Kuznetsov on 05/06/2023.
//

import Foundation
import SwiftUI
import simd

public extension String {
    
    var asHexColorComponents: simd_float4? {
        let hex = trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        
        return switch hex.count {
        case 3: // RGB (12-bit)
            .init(Float((int >> 8) * 17) / 255,
                  Float((int >> 4 & 0xF) * 17) / 255,
                  Float((int & 0xF) * 17) / 255,
                  1)
        case 6: // RGB (24-bit)
            .init(Float(int >> 16) / 255,
                  Float(int >> 8 & 0xFF) / 255,
                  Float(int & 0xFF) / 255,
                  1)
        case 8: // ARGB (32-bit)
            .init(Float(int >> 16 & 0xFF) / 255,
                  Float(int >> 8 & 0xFF) / 255,
                  Float(int & 0xFF) / 255,
                  Float(int >> 24) / 255)
        default: nil
        }
    }
}

public extension Color {
    
    init?(hex: String) {
        guard let components = hex.asHexColorComponents else { return nil }
        self.init(.sRGB,
                  red: Double(components.x),
                  green: Double(components.y),
                  blue:  Double(components.z),
                  opacity: Double(components.w))
    }
    
    static let tappable = Color.init(white: 1, opacity: 0.0001)
    
    var hex: String? {
        let uic = UIColor(self)
        guard let components = uic.cgColor.components, components.count >= 3 else {
            return nil
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        var a = Float(1.0)

        if components.count >= 4 {
            a = Float(components[3])
        }

        if a != Float(1.0) {
            return String(format: "%02lX%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255), lroundf(a * 255))
        } else {
            return String(format: "%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
        }
    }
}
