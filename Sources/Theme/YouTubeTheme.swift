import SwiftUI

public struct YouTubeTheme {
    // Authentic YouTube Dark Mode Colors
    public static let background = Color(hex: "0F0F0F")
    public static let surface = Color(hex: "212121")
    public static let card = Color(hex: "1F1F1F")
    public static let pill = Color(hex: "272727")
    public static let pillSelected = Color.white
    public static let textPrimary = Color.white
    public static let textSecondary = Color(hex: "AAAAAA")
    public static let red = Color(hex: "FF0000")
    public static let border = Color(hex: "333333")
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
