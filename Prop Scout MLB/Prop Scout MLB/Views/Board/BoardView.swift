import SwiftUI

struct BoardView: View {
    @StateObject private var vm = BoardViewModel()
    @EnvironmentObject var picksVM: PicksViewModel
    @State private var showingGames = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.brandBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // MARK: - Primary market tabs
                    primaryTabBar
                        .background(Color.brandSurface)

                    // MARK: - Game sub-tabs (when Games selected)
                    if showingGames {
                        gameSubTabBar
                            .background(Color.brandSurface2)
                    }

                    Divider().background(Color.brandBorder)

                    // MARK: - Content
                    if vm.isLoading && vm.snapshot == nil {
                        ScrollView { BoardSkeletonList() }
                    } else if let error = vm.errorMessage, vm.snapshot == nil {
                        errorView(error)
                    } else {
                        candidateList
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { titleToolbar }
        }
        .task { await vm.loadAndPollIfNeeded() }
        .colorScheme(.dark)
    }

    // MARK: - Primary tabs: HR / Hits / K / Outs / Games
    private var primaryTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(BoardMarket.primaryTabs) { market in
                    tabButton(market, isSelected: !showingGames && vm.selectedMarket == market) {
                        vm.selectedMarket = market
                        showingGames = false
                    }
                }
                // Games tab
                tabButton(label: "Games", color: .brandTextMuted,
                          isSelected: showingGames,
                          isGames: true) {
                    showingGames = true
                }
            }
            .padding(.horizontal, 8)
        }
        .frame(height: 44)
    }

    // MARK: - Game sub-tabs
    private var gameSubTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(BoardMarket.gameTabs) { market in
                    tabButton(market, isSelected: vm.selectedGameMarket == market) {
                        vm.selectedGameMarket = market
                    }
                }
            }
            .padding(.horizontal, 8)
        }
        .frame(height: 36)
    }

    // MARK: - Candidate list
    private var candidateList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                // Snapshot header
                if let label = vm.snapshot?.generatedAt != nil ? Optional(vm.generatedAtLabel) : nil {
                    HStack {
                        Text("Shared daily board · snapshot \(label)")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.brandTextDim)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                }

                let activeMarket = showingGames ? vm.selectedGameMarket : vm.selectedMarket
                let candidates = showingGames
                    ? (vm.snapshot?.candidates(for: vm.selectedGameMarket) ?? [])
                    : vm.currentCandidates

                if candidates.isEmpty && vm.snapshot != nil {
                    emptyState(for: activeMarket)
                } else {
                    ForEach(Array(candidates.enumerated()), id: \.element.id) { index, candidate in
                        BoardCandidateCardView(rank: index + 1, candidate: candidate)
                            .padding(.horizontal, 16)
                    }
                }

                Spacer(minLength: 20)
            }
        }
        .refreshable { await vm.load(refresh: true) }
    }

    // MARK: - Empty state
    private func emptyState(for market: BoardMarket) -> some View {
        // hr/hits depend on confirmed-or-roster lineups, which often aren't
        // posted yet earlier in the day. The snapshot now always returns
        // these keys (possibly as `[]`), so an empty result here means
        // "checked, nothing qualifies yet" rather than "no data at all."
        let isLineupDependent = market == .hr || market == .hits
        return VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 32))
                .foregroundColor(.brandTextDim)
                .padding(.top, 40)
            Text(isLineupDependent ? "Lineups not yet posted" : "No board data yet")
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(.brandTextMuted)
            Text(isLineupDependent ? "Check back closer to first pitch" : "Refreshes daily at 10 AM HI")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.brandTextDim)

            if isLineupDependent {
                Button {
                    Task { await vm.load(refresh: true) }
                } label: {
                    HStack(spacing: 6) {
                        if vm.isRefreshing {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.brandGreen)
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        Text(vm.isRefreshing ? "Checking…" : "Check now")
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    }
                    .foregroundColor(.brandGreen)
                }
                .disabled(vm.isRefreshing)
                .padding(.top, 4)
            }
        }
    }

    // MARK: - Loading / Error

    private func errorView(_ msg: String) -> some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32))
                .foregroundColor(.brandAmber)
            Text(msg)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.brandTextMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Retry") { Task { await vm.load() } }
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundColor(.brandGreen)
            Spacer()
        }
    }

    // MARK: - Tab button builders
    private func tabButton(_ market: BoardMarket, isSelected: Bool, action: @escaping () -> Void) -> some View {
        let stats = vm.hitStats(for: market)
        let showStats = stats.total > 0
        return Button(action: action) {
            VStack(spacing: 3) {
                HStack(spacing: 3) {
                    Text(market.label)
                        .font(.system(size: 12, weight: isSelected ? .bold : .medium, design: .monospaced))
                        .foregroundColor(isSelected ? market.color : .brandTextMuted)
                    if showStats {
                        Text("\(stats.hits)/\(stats.total)")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(isSelected ? market.color.opacity(0.8) : .brandTextDim)
                    }
                }
                Rectangle()
                    .fill(isSelected ? market.color : Color.clear)
                    .frame(height: 2)
            }
        }
        .frame(minWidth: 52)
        .padding(.horizontal, 6)
    }

    private func tabButton(label: String, color: Color, isSelected: Bool, isGames: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Text(label)
                    .font(.system(size: 12, weight: isSelected ? .bold : .medium, design: .monospaced))
                    .foregroundColor(isSelected ? .brandText : color)
                Rectangle()
                    .fill(isSelected ? Color.brandText : Color.clear)
                    .frame(height: 2)
            }
        }
        .frame(minWidth: 52)
        .padding(.horizontal, 6)
    }

    // MARK: - Toolbar
    private var titleToolbar: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            HStack(spacing: 6) {
                Text("⚾")
                    .font(.system(size: 16))
                Text("Board")
                    .font(.system(size: 17, weight: .bold, design: .monospaced))
                    .foregroundColor(.brandText)
            }
        }
    }
}
