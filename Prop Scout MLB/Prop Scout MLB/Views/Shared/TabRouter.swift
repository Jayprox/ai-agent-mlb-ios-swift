import Foundation
import Combine

/// Shared tab-selection state so any tab can programmatically switch the
/// active `MainTabView` tab — e.g. the Slate's "Model Picks · VIEW ALL →"
/// link jumps to the Model tab.
final class TabRouter: ObservableObject {
    @Published var selectedTab: Int = 0

    enum Tab: Int {
        case slate = 0
        case board = 1
        case aiBoard = 2
        case model = 3
        case predict = 4
        case scout = 5
        case chat = 6
        case picks = 7
    }

    func go(to tab: Tab) {
        selectedTab = tab.rawValue
    }
}
