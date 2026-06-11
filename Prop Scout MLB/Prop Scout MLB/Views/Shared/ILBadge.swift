import SwiftUI

/// Small amber "⚠ IL" pill shown next to a player's name when they're on the
/// injured list (per /api/injuries). Shared across Slate, Overview, and Lineup.
struct ILBadge: View {
    var body: some View {
        HStack(spacing: 2) {
            Text("⚠")
                .font(.system(size: 9))
            Text("IL")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
        }
        .foregroundColor(.brandAmber)
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(Color.brandAmber.opacity(0.15))
        .cornerRadius(3)
    }
}
