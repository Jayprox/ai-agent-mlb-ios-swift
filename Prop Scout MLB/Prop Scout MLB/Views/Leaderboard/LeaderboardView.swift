import SwiftUI

struct LeaderboardView: View {
    @StateObject private var vm = LeaderboardViewModel()
    @Environment(\.horizontalSizeClass) var sizeClass
    @State private var showOptInSheet: Bool = false

    private var isIpad: Bool {
        sizeClass == .regular
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.brandBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // MARK: - Sort Control
                    HStack(spacing: 12) {
                        Text("Sort by:")
                            .scaledFont(size: 12, weight: .medium, design: .monospaced)
                            .foregroundColor(.brandTextMuted)

                        Picker("Sort", selection: $vm.sortBy) {
                            ForEach(LeaderboardSortBy.allCases, id: \.self) { sort in
                                Text(sort.label)
                                    .scaledFont(size: 12, design: .monospaced)
                                    .tag(sort)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: vm.sortBy) { newSort in
                            Task {
                                await vm.changeSortBy(newSort)
                            }
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.brandSurface)

                    Divider().background(Color.brandBorder)

                    // MARK: - Leaderboard Content
                    if vm.isLoading && vm.leaderboard.isEmpty {
                        VStack(spacing: 12) {
                            Spacer()
                            ProgressView()
                                .tint(.brandGreen)
                                .scaleEffect(1.2)
                            Text("Loading leaderboard…")
                                .scaledFont(size: 13, design: .monospaced)
                                .foregroundColor(.brandTextMuted)
                            Spacer()
                        }
                    } else if let error = vm.errorMessage {
                        VStack(spacing: 12) {
                            Spacer()
                            Image(systemName: "exclamationmark.triangle")
                                .scaledFont(size: 32)
                                .foregroundColor(.brandAmber)
                            Text(error)
                                .scaledFont(size: 12, design: .monospaced)
                                .foregroundColor(.brandTextMuted)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                            Button("Retry") {
                                Task {
                                    await vm.loadLeaderboard()
                                }
                            }
                            .scaledFont(size: 13, weight: .semibold, design: .monospaced)
                            .foregroundColor(.brandGreen)
                            Spacer()
                        }
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                // User stats section (if logged in)
                                if KeychainManager.loadToken() != nil {
                                    LeaderboardUserStatsView(vm: vm, showOptInSheet: $showOptInSheet)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)

                                    Divider()
                                        .background(Color.brandBorder)
                                }

                                // Column headers
                                LeaderboardHeaderView(sortBy: vm.sortBy)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)

                                Divider()
                                    .background(Color.brandBorder.opacity(0.5))

                                // Leaderboard entries
                                ForEach(vm.leaderboard) { entry in
                                    LeaderboardRowView(entry: entry, sortBy: vm.sortBy)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)

                                    if entry.id != vm.leaderboard.last?.id {
                                        Divider()
                                            .background(Color.brandBorder.opacity(0.3))
                                    }
                                }

                                Spacer(minLength: 20)
                            }
                        }
                        .refreshable {
                            await vm.refresh()
                        }
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Image(systemName: "chart.bar.fill")
                            .scaledFont(size: 14)
                            .foregroundColor(.brandTextMuted)
                        Text("Leaderboard")
                            .scaledFont(size: 17, weight: .bold, design: .monospaced)
                            .foregroundColor(.brandText)
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
        .colorScheme(.dark)
        .sheet(isPresented: $showOptInSheet) {
            LeaderboardOptInSheet(vm: vm)
        }
        .task {
            await vm.loadLeaderboard()
            if KeychainManager.loadToken() != nil {
                await vm.loadUserStats()
            }
        }
    }
}

// MARK: - Header View
struct LeaderboardHeaderView: View {
    let sortBy: LeaderboardSortBy

    var body: some View {
        HStack(spacing: 0) {
            Text("Rank")
                .scaledFont(size: 11, weight: .bold, design: .monospaced)
                .foregroundColor(.brandTextDim)
                .frame(width: 40, alignment: .leading)

            Text("Player")
                .scaledFont(size: 11, weight: .bold, design: .monospaced)
                .foregroundColor(.brandTextDim)
                .frame(maxWidth: .infinity, alignment: .leading)

            if sortBy == .winRate {
                Text("W%")
                    .scaledFont(size: 11, weight: .bold, design: .monospaced)
                    .foregroundColor(.brandTextDim)
                    .frame(width: 50, alignment: .trailing)
            } else {
                Text("P&L")
                    .scaledFont(size: 11, weight: .bold, design: .monospaced)
                    .foregroundColor(.brandTextDim)
                    .frame(width: 50, alignment: .trailing)
            }

            Text("Picks")
                .scaledFont(size: 11, weight: .bold, design: .monospaced)
                .foregroundColor(.brandTextDim)
                .frame(width: 50, alignment: .trailing)
        }
    }
}

// MARK: - Row View
struct LeaderboardRowView: View {
    let entry: LeaderboardEntry
    let sortBy: LeaderboardSortBy

    var body: some View {
        HStack(spacing: 0) {
            // Rank with medal/badge
            VStack(alignment: .center, spacing: 0) {
                Text("\(entry.rank)")
                    .scaledFont(size: 13, weight: .bold, design: .monospaced)
                    .foregroundColor(rankColor)

                if entry.rank <= 3 {
                    Text(rankEmoji(entry.rank))
                        .scaledFont(size: 10)
                }
            }
            .frame(width: 40, alignment: .center)

            // Username
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.username)
                    .scaledFont(size: 13, weight: .bold, design: .monospaced)
                    .foregroundColor(.brandText)
                Text("\(entry.gradedPicks) picks")
                    .scaledFont(size: 10, design: .monospaced)
                    .foregroundColor(.brandTextDim)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Primary metric
            VStack(alignment: .trailing, spacing: 2) {
                if sortBy == .winRate {
                    Text(entry.winRatePct)
                        .scaledFont(size: 13, weight: .bold, design: .monospaced)
                        .foregroundColor(winRateColor(entry.winRate))
                } else {
                    HStack(spacing: 2) {
                        if entry.pnl >= 0 {
                            Image(systemName: "plus")
                                .scaledFont(size: 10, weight: .bold)
                                .foregroundColor(.brandGreen)
                        } else {
                            Image(systemName: "minus")
                                .scaledFont(size: 10, weight: .bold)
                                .foregroundColor(.brandRed)
                        }
                        Text(String(format: "%.1f", abs(entry.pnl)))
                            .scaledFont(size: 13, weight: .bold, design: .monospaced)
                            .foregroundColor(entry.pnl >= 0 ? .brandGreen : .brandRed)
                    }
                }
                Text("H:\(entry.hits) M:\(entry.misses)")
                    .scaledFont(size: 10, design: .monospaced)
                    .foregroundColor(.brandTextDim)
            }
            .frame(width: 50, alignment: .trailing)

            // Graded picks count
            Text("\(entry.gradedPicks)")
                .scaledFont(size: 13, weight: .semibold, design: .monospaced)
                .foregroundColor(.brandGreen)
                .frame(width: 50, alignment: .trailing)
        }
    }

    private var rankColor: Color {
        switch entry.rank {
        case 1: return .brandAmber
        case 2: return .brandCyan
        case 3: return .brandAmber
        default: return .brandTextMuted
        }
    }

    private func rankEmoji(_ rank: Int) -> String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return ""
        }
    }

    private func winRateColor(_ rate: Double) -> Color {
        switch rate {
        case 0.65...: return .brandGreen
        case 0.50..<0.65: return .brandAmber
        default: return .brandRed
        }
    }
}

#Preview {
    LeaderboardView()
}
