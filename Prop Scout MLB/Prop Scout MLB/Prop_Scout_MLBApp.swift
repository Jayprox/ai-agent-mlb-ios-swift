import SwiftUI

@main
struct Prop_Scout_MLBApp: App {
    @StateObject private var auth = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            Group {
                if auth.isAuthenticated {
                    MainTabView()
                } else {
                    LoginView()
                }
            }
            .environmentObject(auth)
            .preferredColorScheme(.dark)
            // Allow Dynamic Type to scale text for readability, but cap at the
            // largest non-accessibility size so dense data tables/cards
            // (Boxscore, Lineup, Board, etc.) don't break their layouts.
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        }
    }
}
