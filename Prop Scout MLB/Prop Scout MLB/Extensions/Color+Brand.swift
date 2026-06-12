import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
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

    // MARK: - Brand Palette
    static let brandBackground  = Color(hex: "#0b0c17")
    static let brandSurface     = Color(hex: "#161827")
    static let brandSurface2    = Color(hex: "#1a1c2e")
    static let brandBorder      = Color(hex: "#1f2437")
    static let brandBorder2     = Color(hex: "#2d3148")
    static let brandText        = Color(hex: "#f9fafb")
    static let brandTextMuted   = Color(hex: "#9ca3af")
    static let brandTextDim     = Color(hex: "#7d8694")
    static let brandGreen       = Color(hex: "#22c55e")
    static let brandAmber       = Color(hex: "#fbbf24")
    static let brandRed         = Color(hex: "#ef4444")
    static let brandBlue        = Color(hex: "#3b82f6")
    static let brandPurple      = Color(hex: "#a78bfa")
    static let brandCyan        = Color(hex: "#38bdf8")

    // MARK: - Market Colors
    static let marketHR     = Color(hex: "#fbbf24")  // amber
    static let marketHits   = Color(hex: "#fb923c")  // orange
    static let marketK      = Color(hex: "#38bdf8")  // cyan
    static let marketOuts   = Color(hex: "#a78bfa")  // purple
    static let marketML     = Color(hex: "#34d399")  // emerald
    static let marketSpread = Color(hex: "#f472b6")  // pink
    static let marketTotal  = Color(hex: "#a3e635")  // lime
    static let marketNRFI   = Color(hex: "#67e8f9")  // light cyan
    static let marketF5ML   = Color(hex: "#fbbf24")  // amber
    static let marketF5RL   = Color(hex: "#f472b6")  // pink
}
