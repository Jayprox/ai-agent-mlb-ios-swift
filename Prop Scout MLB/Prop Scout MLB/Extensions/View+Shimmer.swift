import SwiftUI

private struct ShimmerModifier: ViewModifier {
    let active: Bool
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        if active {
            content
                .overlay(shimmerOverlay.mask(content))
                .onAppear {
                    phase = -1
                    withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: false)) {
                        phase = 1
                    }
                }
        } else {
            content
        }
    }

    private var shimmerOverlay: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let startX = (-1 + phase) * width

            LinearGradient(
                colors: [
                    .brandSurface,
                    .brandBorder2,
                    .brandSurface
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: width * 1.6)
            .offset(x: startX)
        }
        .allowsHitTesting(false)
    }
}

extension View {
    func shimmering(active: Bool = true) -> some View {
        modifier(ShimmerModifier(active: active))
    }
}
