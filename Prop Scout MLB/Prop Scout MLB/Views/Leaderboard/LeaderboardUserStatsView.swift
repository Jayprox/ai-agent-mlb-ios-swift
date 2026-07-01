import SwiftUI

struct LeaderboardUserStatsView: View {
    @ObservedObject var vm: LeaderboardViewModel
    @Binding var showOptInSheet: Bool
    @Environment(\.dismiss) var dismiss
    @State private var showOptOutConfirm: Bool = false

    var body: some View {
        VStack(spacing: 16) {
            // Status card
            if let stats = vm.userStats {
                if stats.optIn {
                    // User is opted in
                    VStack(spacing: 16) {
                        // Rank display
                        if let rank = stats.rank, stats.meetsThreshold {
                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Your Rank")
                                        .scaledFont(size: 11, weight: .bold, design: .monospaced)
                                        .foregroundColor(.brandTextMuted)

                                    HStack(spacing: 8) {
                                        Text("#\(rank)")
                                            .scaledFont(size: 24, weight: .bold, design: .monospaced)
                                            .foregroundColor(.brandGreen)

                                        if rank <= 3 {
                                            Text(rankEmoji(rank))
                                                .scaledFont(size: 20)
                                        }
                                    }
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Username")
                                        .scaledFont(size: 11, weight: .bold, design: .monospaced)
                                        .foregroundColor(.brandTextMuted)

                                    Text(stats.username ?? "—")
                                        .scaledFont(size: 14, weight: .bold, design: .monospaced)
                                        .foregroundColor(.brandText)
                                }
                            }
                            .padding(16)
                            .background(Color.brandSurface)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.brandGreen.opacity(0.3), lineWidth: 1)
                            )
                        } else if !stats.meetsThreshold {
                            // Progress to threshold
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Image(systemName: "info.circle.fill")
                                        .scaledFont(size: 14)
                                        .foregroundColor(.brandAmber)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Not yet on leaderboard")
                                            .scaledFont(size: 12, weight: .bold, design: .monospaced)
                                            .foregroundColor(.brandText)

                                        let pickNeeded = stats.minGradedPicks - stats.stats.gradedPicks
                                        Text("You need \(pickNeeded) more graded pick\(pickNeeded == 1 ? "" : "s") to appear")
                                            .scaledFont(size: 11, design: .monospaced)
                                            .foregroundColor(.brandTextMuted)
                                    }

                                    Spacer()
                                }

                                // Progress bar
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.brandSurface2)

                                    let progress = Double(stats.stats.gradedPicks) / Double(stats.minGradedPicks)
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.brandGreen)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .frame(width: .infinity * CGFloat(min(progress, 1.0)))
                                }
                                .frame(height: 6)
                            }
                            .padding(16)
                            .background(Color.brandSurface)
                            .cornerRadius(10)
                        }

                        // Stats grid
                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                statCard(
                                    label: "Win Rate",
                                    value: stats.stats.winRatePct,
                                    color: winRateColor(stats.stats.winRate)
                                )

                                statCard(
                                    label: "P&L",
                                    value: String(format: "%+.1f", stats.stats.pnl),
                                    color: stats.stats.pnl >= 0 ? .brandGreen : .brandRed
                                )
                            }

                            HStack(spacing: 12) {
                                statCard(label: "Graded", value: "\(stats.stats.gradedPicks)")
                                statCard(label: "Hits", value: "\(stats.stats.hits)")
                                statCard(label: "Misses", value: "\(stats.stats.misses)")
                            }
                        }

                        // Opt-out button
                        Button {
                            showOptOutConfirm = true
                        } label: {
                            Text("Leave Leaderboard")
                                .scaledFont(size: 13, design: .monospaced)
                                .foregroundColor(.brandRed)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(Color.brandRed.opacity(0.1))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.brandRed.opacity(0.3), lineWidth: 0.5)
                                )
                        }
                        .confirmationDialog(
                            "Leave Leaderboard?",
                            isPresented: $showOptOutConfirm,
                            titleVisibility: .visible
                        ) {
                            Button("Leave", role: .destructive) {
                                Task {
                                    let _ = await vm.optOutOfLeaderboard()
                                }
                            }
                            Button("Cancel", role: .cancel) {}
                        } message: {
                            Text("You can join again anytime. Your stats will be saved privately.")
                        }
                    }
                } else {
                    // User not opted in
                    VStack(spacing: 16) {
                        VStack(spacing: 10) {
                            Image(systemName: "chart.bar.fill")
                                .scaledFont(size: 28)
                                .foregroundColor(.brandGreen)

                            Text("Not on Leaderboard")
                                .scaledFont(size: 14, weight: .bold, design: .monospaced)
                                .foregroundColor(.brandText)

                            Text("Join to see how you rank against other users")
                                .scaledFont(size: 11, design: .monospaced)
                                .foregroundColor(.brandTextMuted)
                                .multilineTextAlignment(.center)
                        }

                        Button {
                            showOptInSheet = true
                        } label: {
                            Text("Join Leaderboard")
                                .scaledFont(size: 13, weight: .semibold, design: .monospaced)
                                .foregroundColor(.brandBackground)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(Color.brandGreen)
                                .cornerRadius(8)
                        }

                        // Show their stats privately
                        if stats.stats.gradedPicks > 0 {
                            VStack(spacing: 12) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Your Private Stats")
                                            .scaledFont(size: 12, weight: .bold, design: .monospaced)
                                            .foregroundColor(.brandTextDim)

                                        if let username = stats.username {
                                            Text(username)
                                                .scaledFont(size: 13, weight: .bold, design: .monospaced)
                                                .foregroundColor(.brandText)
                                        }
                                    }

                                    Spacer()
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)

                                HStack(spacing: 12) {
                                    statCard(
                                        label: "Win Rate",
                                        value: stats.stats.winRatePct,
                                        color: winRateColor(stats.stats.winRate)
                                    )

                                    statCard(
                                        label: "P&L",
                                        value: String(format: "%+.1f", stats.stats.pnl),
                                        color: stats.stats.pnl >= 0 ? .brandGreen : .brandRed
                                    )
                                }

                                HStack(spacing: 12) {
                                    statCard(label: "Graded", value: "\(stats.stats.gradedPicks)")
                                    statCard(label: "Hits", value: "\(stats.stats.hits)")
                                    statCard(label: "Misses", value: "\(stats.stats.misses)")
                                }
                            }
                            .padding(16)
                            .background(Color.brandSurface)
                            .cornerRadius(10)
                        }
                    }
                }
            } else {
                // Loading
                VStack(spacing: 12) {
                    ProgressView()
                        .tint(.brandGreen)
                    Text("Loading stats…")
                        .scaledFont(size: 12, design: .monospaced)
                        .foregroundColor(.brandTextMuted)
                }
            }

            Spacer()
        }
        .padding(16)
    }

    private func statCard(label: String, value: String, color: Color = .brandGreen) -> some View {
        VStack(alignment: .center, spacing: 6) {
            Text(value)
                .scaledFont(size: 14, weight: .bold, design: .monospaced)
                .foregroundColor(color)

            Text(label)
                .scaledFont(size: 10, design: .monospaced)
                .foregroundColor(.brandTextDim)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color.brandSurface)
        .cornerRadius(8)
    }

    private func winRateColor(_ rate: Double) -> Color {
        switch rate {
        case 0.65...: return .brandGreen
        case 0.50..<0.65: return .brandAmber
        default: return .brandRed
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
}

#Preview {
    @State var showOptInSheet = false
    return LeaderboardUserStatsView(vm: LeaderboardViewModel(), showOptInSheet: $showOptInSheet)
}
