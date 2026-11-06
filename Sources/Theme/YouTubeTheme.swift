import SwiftUI
import UIKit

public struct YouTubeTheme {
    // Dynamic background matching YouTube's authentic light (#FFFFFF) & dark (#0F0F0F)
    public static var background: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 15/255, green: 15/255, blue: 15/255, alpha: 1.0)
                : UIColor.white
        })
    }

    public static var surface: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 33/255, green: 33/255, blue: 33/255, alpha: 1.0)
                : UIColor(red: 242/255, green: 242/255, blue: 242/255, alpha: 1.0)
        })
    }

    public static var card: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 31/255, green: 31/255, blue: 31/255, alpha: 1.0)
                : UIColor(red: 248/255, green: 248/255, blue: 248/255, alpha: 1.0)
        })
    }

    public static var pill: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 39/255, green: 39/255, blue: 39/255, alpha: 1.0)
                : UIColor(red: 232/255, green: 232/255, blue: 232/255, alpha: 1.0)
        })
    }

    public static var pillSelected: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor.white
                : UIColor(red: 15/255, green: 15/255, blue: 15/255, alpha: 1.0)
        })
    }

    public static var textOnPillSelected: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 15/255, green: 15/255, blue: 15/255, alpha: 1.0)
                : UIColor.white
        })
    }

    public static var textPrimary: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor.white
                : UIColor(red: 15/255, green: 15/255, blue: 15/255, alpha: 1.0)
        })
    }

    public static var textSecondary: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 170/255, green: 170/255, blue: 170/255, alpha: 1.0)
                : UIColor(red: 96/255, green: 96/255, blue: 96/255, alpha: 1.0)
        })
    }

    public static let red = Color(hex: "FF0000")

    public static var border: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 51/255, green: 51/255, blue: 51/255, alpha: 1.0)
                : UIColor(red: 224/255, green: 224/255, blue: 224/255, alpha: 1.0)
        })
    }
}

extension Color {
    public init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
