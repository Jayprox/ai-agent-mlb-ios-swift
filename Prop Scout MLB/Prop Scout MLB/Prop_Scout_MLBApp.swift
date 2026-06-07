import SwiftUI

@main
struct Prop_Scout_MLBApp: App {
    @StateObject private var auth = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            Group {
                if auth.isAuthenticated {
                    // Placeholder — replaced by MainTabView in next step
                    Text("Authenticated ✓")
                        .foregroundColor(.brandText)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.brandBackground.ignoresSafeArea())
                } else {
                    LoginView()
                }
            }
            .environmentObject(auth)
            .preferredColorScheme(.dark)
        }
    }
}
