import SwiftUI

struct LiveBadge: View {
    @State private var pulsing = false

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color.brandRed)
                .frame(width: 6, height: 6)
                .opacity(pulsing ? 0.4 : 1.0)
                .animation(.easeInOut(duration: 0.8).repeatForever(), value: pulsing)
            Text("LIVE")
                .scaledFont(size: 10, weight: .bold, design: .monospaced)
                .foregroundColor(.brandRed)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(Color.brandRed.opacity(0.12))
        .cornerRadius(4)
        .onAppear { pulsing = true }
    }
}

struct FinalBadge: View {
    var body: some View {
        Text("FINAL")
            .scaledFont(size: 10, weight: .bold, design: .monospaced)
            .foregroundColor(.brandTextMuted)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Color.brandSurface2)
            .cornerRadius(4)
    }
}

struct PPDBadge: View {
    var body: some View {
        Text("PPD")
            .scaledFont(size: 10, weight: .bold, design: .monospaced)
            .foregroundColor(.brandAmber)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Color.brandAmber.opacity(0.12))
            .cornerRadius(4)
    }
}
