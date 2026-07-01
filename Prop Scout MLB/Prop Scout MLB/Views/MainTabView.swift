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

            MoreView()
                .environmentObject(picksVM)
                .environmentObject(router)
                .tabItem { Label("More", systemImage: "ellipsis") }
                .tag(4)
        }
        .accentColor(.brandGreen)
        .colorScheme(.dark)
    }
}
