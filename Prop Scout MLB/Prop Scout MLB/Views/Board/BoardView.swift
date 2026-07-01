import SwiftUI

struct BoardView: View {
    @StateObject private var vm = BoardViewModel()
    @EnvironmentObject var picksVM: PicksViewModel
    @State private var showingGames = false
    @State private var gameFilter: GameFilter = .all
    @Environment(\.horizontalSizeClass) var sizeClass

    enum GameFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case live = "Live"
        case upcoming = "Upcoming"
        case finished = "Finished"

        var id: String { rawValue }
    }

    private var isIpad: Bool {
        sizeClass == .regular
    }

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

                        Divider().background(Color.brandBorder)
                    }

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
        .navigationViewStyle(.stack)
        .task { await vm.loadAndPollIfNeeded() }
        .colorScheme(.dark)
    }

    // MARK: - Primary tabs: HR / Hits / K / Outs / Games (Adaptive for iPhone/iPad)
    private var primaryTabBar: some View {
        Group {
            if isIpad {
                // iPad: All tabs in one row, spread equally
                HStack(spacing: 8) {
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
                .padding(.horizontal, 12)
            } else {
                // iPhone: Two-row layout (3 + 2)
                VStack(spacing: 6) {
                    // Row 1: HR, Hits, K
                    HStack(spacing: 6) {
                        tabButton(BoardMarket.hr, isSelected: !showingGames && vm.selectedMarket == .hr) {
                            vm.selectedMarket = .hr
                            showingGames = false
                        }
                        tabButton(BoardMarket.hits, isSelected: !showingGames && vm.selectedMarket == .hits) {
                            vm.selectedMarket = .hits
                            showingGames = false
                        }
                        tabButton(BoardMarket.k, isSelected: !showingGames && vm.selectedMarket == .k) {
                            vm.selectedMarket = .k
                            showingGames = false
                        }
                    }

                    // Row 2: Outs, Games
                    HStack(spacing: 6) {
                        tabButton(BoardMarket.outs, isSelected: !showingGames && vm.selectedMarket == .outs) {
                            vm.selectedMarket = .outs
                            showingGames = false
                        }
                        tabButton(label: "Games", color: .brandTextMuted,
                                  isSelected: showingGames,
                                  isGames: true) {
                            showingGames = true
                        }
                        Spacer()
                    }
                }
                .padding(.horizontal, 8)
            }
        }
        .frame(height: isIpad ? 54 : 108)
    }

    // MARK: - Game sub-tabs (Adaptive for iPhone/iPad)
    private var gameSubTabBar: some View {
        Group {
            if isIpad {
                // iPad: All tabs in one row, spread equally
                HStack(spacing: 8) {
                    ForEach(BoardMarket.gameTabs) { market in
                        tabButton(market, isSelected: vm.selectedGameMarket == market) {
                            vm.selectedGameMarket = market
                        }
                    }
                }
                .padding(.horizontal, 12)
            } else {
                // iPhone: Two-row layout (3 + 3)
                VStack(spacing: 6) {
                    // Row 1: NRFI, Total, ML
                    HStack(spacing: 6) {
                        tabButton(BoardMarket.nrfi, isSelected: vm.selectedGameMarket == .nrfi) {
                            vm.selectedGameMarket = .nrfi
                        }
                        tabButton(BoardMarket.total, isSelected: vm.selectedGameMarket == .total) {
                            vm.selectedGameMarket = .total
                        }
                        tabButton(BoardMarket.ml, isSelected: vm.selectedGameMarket == .ml) {
                            vm.selectedGameMarket = .ml
                        }
                    }

                    // Row 2: Spread, F5 ML, F5 Spread
                    HStack(spacing: 6) {
                        tabButton(BoardMarket.spread, isSelected: vm.selectedGameMarket == .spread) {
                            vm.selectedGameMarket = .spread
                        }
                        tabButton(BoardMarket.f5ml, isSelected: vm.selectedGameMarket == .f5ml) {
                            vm.selectedGameMarket = .f5ml
                        }
                        tabButton(BoardMarket.f5spread, isSelected: vm.selectedGameMarket == .f5spread) {
                            vm.selectedGameMarket = .f5spread
                        }
                    }
                }
                .padding(.horizontal, 8)
            }
        }
        .frame(height: isIpad ? 54 : 108)
    }

    // MARK: - Game status filter bar
    private var gameFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(GameFilter.allCases) { filter in
                    Button {
                        gameFilter = filter
                    } label: {
                        Text(filter.rawValue)
                            .scaledFont(size: 11, weight: gameFilter == filter ? .bold : .medium, design: .monospaced)
                            .foregroundColor(gameFilter == filter ? .brandGreen : .brandTextMuted)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(gameFilter == filter ? Color.brandGreen.opacity(0.12) : Color.clear)
                            .cornerRadius(6)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 16)
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
                            .scaledFont(size: 10, design: .monospaced)
                            .foregroundColor(.brandTextDim)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                }

                let activeMarket = showingGames ? vm.selectedGameMarket : vm.selectedMarket
                let candidates = filteredCandidates

                if candidates.isEmpty && vm.snapshot != nil {
                    emptyState(for: activeMarket)
                } else {
                    ForEach(Array(candidates.enumerated()), id: \.element.id) { index, candidate in
                        BoardCandidateCardView(
                            rank: index + 1,
                            candidate: candidate,
                            fallbackOdds: vm.fallbackOdds(for: candidate.gamePk),
                            boardVM: vm
                        )
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
        let isLineupDependent = market == .hr || market == .hits

        // Determine message based on filter selection
        let (title, subtitle) = emptyStateMessage(isLineupDependent: isLineupDependent)

        return VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .scaledFont(size: 32)
                .foregroundColor(.brandTextDim)
                .padding(.top, 40)
            Text(title)
                .scaledFont(size: 13, design: .monospaced)
                .foregroundColor(.brandTextMuted)
            Text(subtitle)
                .scaledFont(size: 11, design: .monospaced)
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
                                .scaledFont(size: 11, weight: .semibold)
                        }
                        Text(vm.isRefreshing ? "Checking…" : "Check now")
                            .scaledFont(size: 12, weight: .semibold, design: .monospaced)
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
                .scaledFont(size: 32)
                .foregroundColor(.brandAmber)
            Text(msg)
                .scaledFont(size: 12, design: .monospaced)
                .foregroundColor(.brandTextMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Retry") { Task { await vm.load() } }
                .scaledFont(size: 13, weight: .semibold, design: .monospaced)
                .foregroundColor(.brandGreen)
            Spacer()
        }
    }

    // MARK: - Tab button builders
    private func tabButton(_ market: BoardMarket, isSelected: Bool, action: @escaping () -> Void) -> some View {
        let stats = vm.hitStats(for: market)
        let showStats = stats.total > 0
        return Button(action: action) {
            VStack(spacing: 4) {
                HStack(spacing: 3) {
                    Text(market.label)
                        .scaledFont(size: 13, weight: isSelected ? .bold : .medium, design: .monospaced)
                        .foregroundColor(isSelected ? market.color : .brandTextMuted)
                    if showStats {
                        Text("\(stats.hits)/\(stats.total)")
                            .scaledFont(size: 10, design: .monospaced)
                            .foregroundColor(isSelected ? market.color.opacity(0.8) : .brandTextDim)
                    }
                }
                Rectangle()
                    .fill(isSelected ? market.color : Color.clear)
                    .frame(height: 2)
            }
            .frame(minHeight: 44)
        }
        .frame(maxWidth: .infinity)
    }

    private func tabButton(label: String, color: Color, isSelected: Bool, isGames: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(label)
                    .scaledFont(size: 13, weight: isSelected ? .bold : .medium, design: .monospaced)
                    .foregroundColor(isSelected ? .brandText : color)
                Rectangle()
                    .fill(isSelected ? Color.brandText : Color.clear)
                    .frame(height: 2)
            }
            .frame(minHeight: 44)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Empty state message
    private func emptyStateMessage(isLineupDependent: Bool) -> (title: String, subtitle: String) {
        if gameFilter == .finished {
            return ("No finished games", "Games graded will appear here")
        }
        if gameFilter == .live {
            return ("No live games", "Games in progress will appear here")
        }
        if gameFilter == .upcoming {
            return ("No upcoming games", "Games not yet started will appear here")
        }
        // Default: .all filter or no specific filter
        if isLineupDependent {
            return ("Lineups not yet posted", "Check back closer to first pitch")
        }
        return ("No board data yet", "Refreshes daily at 10 AM HI")
    }

    // MARK: - Filtered candidates
    private var filteredCandidates: [BoardCandidate] {
        let baseList = showingGames
            ? (vm.snapshot?.candidates(for: vm.selectedGameMarket) ?? [])
            : vm.currentCandidates

        // Apply game status filter to all tabs
        return baseList.filter { candidate in
            switch gameFilter {
            case .all:
                return true
            case .live:
                return candidate.isLive
            case .upcoming:
                return candidate.isUpcoming
            case .finished:
                return candidate.isFinished
            }
        }
    }

    // MARK: - Toolbar
    private var titleToolbar: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text("Board")
                .scaledFont(size: 17, weight: .bold, design: .monospaced)
                .foregroundColor(.brandText)
        }
    }
}
