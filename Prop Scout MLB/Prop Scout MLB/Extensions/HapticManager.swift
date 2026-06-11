import UIKit

enum HapticManager {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let g = UIImpactFeedbackGenerator(style: style)
        g.prepare()
        g.impactOccurred()
    }

    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let g = UINotificationFeedbackGenerator()
        g.prepare()
        g.notificationOccurred(type)
    }

    static func success() { notification(.success) }
    static func error()   { notification(.error) }
    static func warning() { notification(.warning) }
    static func light()   { impact(.light) }
    static func rigid()   { impact(.rigid) }
}
