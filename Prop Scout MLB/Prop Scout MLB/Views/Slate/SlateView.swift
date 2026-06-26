import SwiftUI

struct SlateView: View {
    @StateObject private var vm = SlateViewModel()
    @EnvironmentObject var router: TabRouter

    var body: some View {
        NavigationView {
            ZStack {
                Color.brandBackground.ignoresSafeArea()

                if vm.isLoading && vm.games.isEmpty {
                    ScrollView { SlateSkeletonList() }
                } else if let error = vm.errorMessage, vm.games.isEmpty {
                    errorView(error)
                } else {
                    gameList
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { titleToolbar }
        }
        .navigationViewStyle(.stack)
        .task { await vm.load() }
        .onDisappear { vm.stopPolling() }
        .colorScheme(.dark)
    }

    // MARK: - Game list
    private var gameList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                // Model Picks preview
                if !vm.topModelPicks.isEmpty {
                    modelPicksPreview
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                }

                // Header
                HStack {
                    Text("TODAY'S SLATE")
                        .scaledFont(size: 11, weight: .bold, design: .monospaced)
                        .foregroundColor(.brandTextDim)
                        .kerning(1.5)
                    Text("·")
                        .foregroundColor(.brandTextDim)
                    Text("\(vm.gameCount) GAMES")
                        .scaledFont(size: 11, weight: .bold, design: .monospaced)
                        .foregroundColor(.brandTextDim)
                    if vm.liveCount > 0 {
                        Text("·")
                            .foregroundColor(.brandTextDim)
                        LiveBadge()
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                // Game cards
                ForEach(vm.games) { game in
                    NavigationLink {
                        GameDetailView(
                            game: game,
                            odds: vm.odds(for: game),
                            weather: vm.weather(for: game),
                            nrfiBundle: vm.nrfi(for: game)
                        )
                    } label: {
                        SlateCardView(
                            game: game,
                            odds: vm.odds(for: game),
                            nrfi: vm.nrfi(for: game),
                            weather: vm.weather(for: game),
                            linescore: vm.linescore(for: game),
                            kHint: vm.kHint(for: game),
                            awayPitcherEra: vm.pitcherStats(for: game.probablePitchers?.away?.id)?.era,
                            homePitcherEra: vm.pitcherStats(for: game.probablePitchers?.home?.id)?.era
                        )
                        .padding(.horizontal, 16)
                    }
                    .buttonStyle(.plain)
                }

                Spacer(minLength: 20)
            }
        }
        .refreshable { await vm.load() }
    }

    // MARK: - Model Picks preview
    private var modelPicksPreview: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("— MODEL PICKS")
                    .scaledFont(size: 11, weight: .bold, design: .monospaced)
                    .foregroundColor(.brandTextDim)
                    .kerning(1)
                Spacer()
                Button {
                    HapticManager.light()
                    router.go(to: .model)
                } label: {
                    HStack(spacing: 2) {
                        Text("VIEW ALL")
                        Image(systemName: "arrow.right")
                            .scaledFont(size: 9, weight: .bold)
                    }
                    .scaledFont(size: 10, weight: .bold, design: .monospaced)
                    .foregroundColor(.brandGreen)
                }
            }

            ForEach(Array(vm.topModelPicks.enumerated()), id: \.element.id) { index, edge in
                if index > 0 {
                    Divider().background(Color.brandBorder)
                }
                modelPickRow(rank: index + 1, edge: edge)
            }
        }
        .padding(14)
        .background(Color.brandSurface)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.brandBorder, lineWidth: 1))
    }

    private func modelPickRow(rank: Int, edge: AIBoardEdge) -> some View {
        HStack(alignment: .center, spacing: 10) {
            Text("\(rank)")
                .scaledFont(size: 11, weight: .bold, design: .monospaced)
                .foregroundColor(.brandTextDim)
                .frame(width: 14)

            VStack(alignment: .leading, spacing: 3) {
                Text(modelPickTitle(edge))
                    .scaledFont(size: 13, weight: .bold, design: .monospaced)
                    .foregroundColor(.brandText)
                HStack(spacing: 6) {
                    Text(edge.displayGameLabel)
                        .scaledFont(size: 10, design: .monospaced)
                        .foregroundColor(.brandTextDim)
                    Text("✓ LINEUP")
                        .scaledFont(size: 8, weight: .bold, design: .monospaced)
                        .foregroundColor(.brandGreen)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.brandGreen.opacity(0.12))
                        .cornerRadius(4)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                let lean = (edge.lean ?? "OVER").uppercased()
                Text(lean)
                    .scaledFont(size: 10, weight: .bold, design: .monospaced)
                    .foregroundColor(lean == "OVER" ? .brandGreen : .brandRed)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background((lean == "OVER" ? Color.brandGreen : Color.brandRed).opacity(0.12))
                    .cornerRadius(4)
                if let sim = edge.simConfidence {
                    Text("\(sim)%")
                        .scaledFont(size: 11, weight: .bold, design: .monospaced)
                        .foregroundColor(.brandPurple)
                }
            }
        }
    }

    private func modelPickTitle(_ edge: AIBoardEdge) -> String {
        var s = "\(edge.displayName) \(edge.pickMarketLabel) O/U"
        if let line = edge.pickBookLine {
            s += " \(line == line.rounded() ? "\(Int(line))" : String(format: "%.1f", line))"
        }
        return s
    }

    // MARK: - Error
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .scaledFont(size: 32)
                .foregroundColor(.brandAmber)
            Text(message)
                .scaledFont(size: 13, design: .monospaced)
                .foregroundColor(.brandTextMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Retry") { Task { await vm.load() } }
                .scaledFont(size: 13, weight: .semibold, design: .monospaced)
                .foregroundColor(.brandGreen)
        }
    }

    // MARK: - Toolbar
    private var titleToolbar: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text("Chalk That")
                .scaledFont(size: 17, weight: .bold, design: .monospaced)
                .foregroundColor(.brandText)
        }
    }
}
