import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var auth: AuthViewModel
    @StateObject private var picksVM = PicksViewModel()
    @StateObject private var router = TabRouter()

    var body: some View {
        TabView(selection: $router.selectedTab) {
            SlateView()
                .environmentObject(picksVM)
                .environmentObject(router)
                .tabItem { Label("Slate", systemImage: "calendar") }
                .tag(0)

            BoardView()
                .environmentObject(picksVM)
                .tabItem { Label("Board", systemImage: "chart.bar.fill") }
                .tag(1)

            AIBoardView()
                .environmentObject(picksVM)
                .tabItem { Label("AI Board", systemImage: "sparkles") }
                .tag(2)

            ModelPicksView()
                .environmentObject(picksVM)
                .tabItem { Label("Model", systemImage: "cpu") }
                .tag(3)

            PredictView()
                .environmentObject(picksVM)
                .tabItem { Label("Predict", systemImage: "bolt.fill") }
                .tag(4)

            ScoutView()
                .environmentObject(picksVM)
                .tabItem { Label("Scout", systemImage: "scope") }
                .tag(5)

            ChatView()
                .tabItem { Label("Chat", systemImage: "bubble.left.and.bubble.right.fill") }
                .tag(6)

            PicksView()
                .environmentObject(picksVM)
                .tabItem { Label("Picks", systemImage: "note.text") }
                .tag(7)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(8)
        }
        .accentColor(.brandGreen)
        .colorScheme(.dark)
    }
}
