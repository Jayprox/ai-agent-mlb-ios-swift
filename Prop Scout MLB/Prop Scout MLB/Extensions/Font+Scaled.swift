import SwiftUI
import UIKit

/// Applies a fixed-point font size that scales with the user's Dynamic Type
/// setting, similar to `.font(.system(size:weight:design:))` but accessible.
private struct ScaledFontModifier: ViewModifier {
    @ScaledMetric private var scaledSize: CGFloat
    let weight: Font.Weight
    let design: Font.Design

    init(size: CGFloat, weight: Font.Weight, design: Font.Design) {
        self._scaledSize = ScaledMetric(wrappedValue: size)
        self.weight = weight
        self.design = design
    }

    func body(content: Content) -> some View {
        content.font(.system(size: scaledSize, weight: weight, design: design))
    }
}

extension View {
    /// Drop-in replacement for `.font(.system(size:weight:design:))` that
    /// scales with the user's Dynamic Type text size setting.
    func scaledFont(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> some View {
        modifier(ScaledFontModifier(size: size, weight: weight, design: design))
    }
}

extension Text {
    /// Text-specific overload, preferred by the compiler over the `View`
    /// version above when called directly on a `Text`. Returning `Text`
    /// (rather than `some View`) keeps the `Text` concatenation operator
    /// (`+`) working, e.g. `Text("a").scaledFont(...) + Text("b").scaledFont(...)`.
    /// Scales via `UIFontMetrics` so it still tracks the system Dynamic
    /// Type setting.
    func scaledFont(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> Text {
        let scaledSize = UIFontMetrics.default.scaledValue(for: size)
        return self.font(.system(size: scaledSize, weight: weight, design: design))
    }
}
