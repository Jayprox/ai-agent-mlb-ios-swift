import SwiftUI

enum GameTab: String, CaseIterable {
    case overview = "OVERVIEW"
    case lineup   = "LINEUP"
    case arsenal  = "ARSENAL"
    case intel    = "INTEL"
    case bullpen  = "BULLPEN"
    case boxscore = "BOX"
}

struct GameDetailView: View {
    let game: SlateGame
    let odds: OddsData?
    let weather: WeatherData?
    let nrfiBundle: NRFIData?

    @StateObject private var vm = GameDetailViewModel()
    @State private var selectedTab: GameTab = .overview

    var body: some View {
        ZStack {
            Color.brandBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: - Game header
                gameHeader
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.brandSurface)

                Divider().background(Color.brandBorder)

                // MARK: - Tab bar
                tabBar
                    .background(Color.brandSurface)

                Divider().background(Color.brandBorder)

                // MARK: - Tab content
                if vm.isLoading {
                    Spacer()
                    ProgressView().tint(.brandGreen).scaleEffect(1.2)
                    Spacer()
                } else {
                    TabView(selection: $selectedTab) {
                        GameOverviewView(game: game, vm: vm)
                            .tag(GameTab.overview)
                        GameLineupView(game: game, vm: vm)
                            .tag(GameTab.lineup)
                        GameArsenalView(game: game, vm: vm)
                            .tag(GameTab.arsenal)
                        GameIntelView(game: game, vm: vm)
                            .tag(GameTab.intel)
                        GameBullpenView(game: game, vm: vm)
                            .tag(GameTab.bullpen)
                        GameBoxscoreView(game: game, vm: vm)
                            .tag(GameTab.boxscore)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .colorScheme(.dark)
        .task { await vm.load(game: game, odds: odds, weather: weather) }
    }

    // MARK: - Game header
    private var gameHeader: some View {
        VStack(spacing: 8) {
            // Teams + score
            HStack(alignment: .center) {
                // Away
                VStack(spacing: 2) {
                    Text(game.away.abbr)
                        .scaledFont(size: 28, weight: .bold, design: .monospaced)
                        .foregroundColor(.brandText)
                    Text(game.away.name)
                        .scaledFont(size: 10, design: .monospaced)
                        .foregroundColor(.brandTextMuted)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)

                // Center info
                VStack(spacing: 4) {
                    if let ls = vm.linescore, ls.inning > 0 {
                        HStack(spacing: 8) {
                            Text("\(ls.awayScore)")
                                .scaledFont(size: 22, weight: .bold, design: .monospaced)
                                .foregroundColor(.brandText)
                            Text("–")
                                .foregroundColor(.brandTextDim)
                            Text("\(ls.homeScore)")
                                .scaledFont(size: 22, weight: .bold, design: .monospaced)
                                .foregroundColor(.brandText)
                        }
                        Text(game.isLive ? "\(ls.isTop ? "▲" : "▼")\(ls.inning)" : "FINAL")
                            .scaledFont(size: 11, weight: .bold, design: .monospaced)
                            .foregroundColor(game.isLive ? .brandRed : .brandTextMuted)
                    } else {
                        Text("@")
                            .scaledFont(size: 16, weight: .medium)
                            .foregroundColor(.brandTextDim)
                        Text(game.formattedTime)
                            .scaledFont(size: 12, design: .monospaced)
                            .foregroundColor(.brandTextMuted)
                    }
                }
                .frame(maxWidth: .infinity)

                // Home
                VStack(spacing: 2) {
                    Text(game.home.abbr)
                        .scaledFont(size: 28, weight: .bold, design: .monospaced)
                        .foregroundColor(.brandText)
                    Text(game.home.name)
                        .scaledFont(size: 10, design: .monospaced)
                        .foregroundColor(.brandTextMuted)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
            }

            // Venue + badges
            VStack(spacing: 6) {
                if let venue = game.venue {
                    Text(venue)
                        .scaledFont(size: 11, design: .monospaced)
                        .foregroundColor(.brandTextDim)
                }

                HStack(spacing: 8) {
                    // Weather badge
                    if let w = weather ?? vm.weather {
                        if w.isDome {
                            badge("DOME", color: .brandTextDim)
                        } else if let temp = w.tempString as String? {
                            badge(temp, color: .brandCyan)
                        }
                    }
                    // O/U badge
                    if let o = odds ?? vm.odds, let total = o.total {
                        badge("O/U \(total)", color: .brandAmber)
                    }
                    // Live badge
                    if game.isLive {
                        LiveBadge()
                    }
                }
            }
        }
    }

    // MARK: - Tab bar
    private var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(GameTab.allCases, id: \.self) { tab in
                    Button {
                        HapticManager.light()
                        selectedTab = tab
                    } label: {
                        VStack(spacing: 3) {
                            Text(tab.rawValue)
                                .scaledFont(size: 11, weight: selectedTab == tab ? .bold : .medium,
                                              design: .monospaced)
                                .foregroundColor(selectedTab == tab ? .brandText : .brandTextMuted)
                            Rectangle()
                                .fill(selectedTab == tab ? Color.brandGreen : Color.clear)
                                .frame(height: 2)
                        }
                    }
                    .frame(minWidth: 72)
                    .padding(.vertical, 10)
                }
            }
            .padding(.horizontal, 8)
        }
    }

    // MARK: - Helper
    private func badge(_ text: String, color: Color) -> some View {
        Text(text)
            .scaledFont(size: 10, weight: .semibold, design: .monospaced)
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .cornerRadius(5)
    }
}
