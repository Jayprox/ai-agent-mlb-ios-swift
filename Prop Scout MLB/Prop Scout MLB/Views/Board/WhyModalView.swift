import SwiftUI

struct WhyModalView: View {
    let candidate: BoardCandidate
    var rank: Int? = nil
    @Environment(\.dismiss) private var dismiss

    // Client-side for prop markets; API-provided for game markets
    private var whyFactors: [ScoreSignal] { WhyFactorsBuilder.build(for: candidate) }

    /// Confidence shown in the lean pill — always from the API.
    private var displayConfidence: Int? { candidate.simConfidence }

    var body: some View {
        ZStack {
            Color.brandBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // MARK: - Header
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            // "#1 · K PROPS" breadcrumb
                            HStack(spacing: 6) {
                                if let r = rank {
                                    Text("#\(r)")
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .foregroundColor(.brandTextDim)
                                    Text("·")
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundColor(.brandTextDim)
                                }
                                MarketBadge(market: candidate.market)
                                Text("PROPS")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(.brandTextDim)
                                    .kerning(1)
                            }
                            Text(candidate.displayName)
                                .font(.system(size: 20, weight: .bold, design: .monospaced))
                                .foregroundColor(.brandText)
                            if candidate.displayGameLabel != candidate.displayName,
                               !candidate.displayGameLabel.isEmpty {
                                Text(candidate.displayGameLabel)
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(.brandCyan)   // teal, matching web
                            }
                        }
                        Spacer()
                        VStack(spacing: 8) {
                            // ✕ close button
                            Button { dismiss() } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.brandTextMuted)
                                    .frame(width: 26, height: 26)
                                    .background(Color.brandSurface2)
                                    .clipShape(Circle())
                                    .frame(width: 44, height: 44)
                                    .contentShape(Rectangle())
                            }
                            .accessibilityLabel("Close")
                            // Score badge
                            VStack(spacing: 2) {
                                Text("\(candidate.score)")
                                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                                    .foregroundColor(candidate.scoreColor)
                                Text("SCORE")
                                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                                    .foregroundColor(.brandTextDim)
                                    .kerning(1)
                            }
                            .frame(width: 52, height: 52)
                            .background(candidate.scoreColor.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    .padding(20)

                    Divider().background(Color.brandBorder)

                    // MARK: - Signal breakdown rows
                    if !whyFactors.isEmpty {
                        VStack(spacing: 0) {
                            ForEach(whyFactors) { signal in
                                SignalRow(signal: signal)
                                Divider().background(Color.brandBorder).padding(.leading, 16)
                            }
                        }
                    } else {
                        // Fallback: simple score bar when no factors available
                        scoreBarFallback
                            .padding(16)
                    }

                    // MARK: - Analysis + lean pill
                    if let summary = candidate.boardSummary, !summary.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(alignment: .top) {
                                Text(summary)
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(.brandTextMuted)
                                    .lineSpacing(4)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer(minLength: 12)
                                // Lean pill — "● OVER 62%"
                                if !candidate.displayLean.isEmpty {
                                    leanPill
                                }
                            }
                        }
                        .padding(16)
                        .background(Color.brandSurface)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }

                    // MARK: - Lean / Line / SIM tiles (when no summary)
                    if candidate.boardSummary == nil || candidate.boardSummary?.isEmpty == true {
                        HStack(spacing: 8) {
                            let lean = candidate.displayLean
                            if !lean.isEmpty {
                                statTile(label: "LEAN", value: lean,
                                         valueColor: leanColor(candidate.leanColorBasis))
                            }
                            if let line = candidate.bookLine {
                                statTile(label: "LINE",
                                         value: line == line.rounded() ? "\(Int(line))" : String(format: "%.1f", line),
                                         valueColor: .brandText)
                            }
                            if let conf = displayConfidence {
                                statTile(label: "SIM", value: "\(conf)%", valueColor: .brandPurple)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                    }

                    // MARK: - Pitcher stats
                    if candidate.isPitcherMarket {
                        statsGrid([
                            ("ERA",    candidate.era    ?? "—"),
                            ("WHIP",   candidate.whip   ?? "—"),
                            ("IP/gs",  candidate.avgIP  ?? "—"),
                            ("Avg K3", candidate.avgK3  ?? "—")
                        ])
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                    }

                    // MARK: - Batter stats
                    if candidate.isBatterMarket {
                        statsGrid([
                            ("AVG", candidate.avg ?? "—"),
                            ("OPS", candidate.ops ?? "—")
                        ])
                        .padding(.horizontal, 16)
                        .padding(.bottom, 4)
                        if let hr = candidate.hitRate {
                            hitRateRow(hr)
                                .padding(.horizontal, 16)
                                .padding(.bottom, 12)
                        }
                    }

                    Spacer(minLength: 32)
                }
            }
        }
        .colorScheme(.dark)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Lean pill
    private var leanPill: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(leanColor(candidate.leanColorBasis))
                .frame(width: 6, height: 6)
            Text(candidate.displayLean.uppercased())
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(leanColor(candidate.leanColorBasis))
            if let conf = displayConfidence {
                Text("\(conf)%")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(.brandTextMuted)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(leanColor(candidate.leanColorBasis).opacity(0.12))
        .cornerRadius(20)
    }

    // MARK: - Score bar fallback
    private var scoreBarFallback: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("SCORE")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.brandTextDim)
                    .kerning(1.5)
                Spacer()
                Text("\(candidate.score)/100")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(candidate.scoreColor)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(Color.brandBorder2).frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(candidate.scoreColor)
                        .frame(width: geo.size.width * CGFloat(candidate.score) / 100, height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(14)
        .background(Color.brandSurface)
        .cornerRadius(10)
    }

    // MARK: - Helpers
    private func statTile(label: String, value: String, valueColor: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(valueColor)
            Text(label)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.brandTextDim)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color.brandSurface)
        .cornerRadius(10)
    }

    private func statsGrid(_ items: [(String, String)]) -> some View {
        HStack(spacing: 8) {
            ForEach(items, id: \.0) { label, value in
                VStack(spacing: 4) {
                    Text(value)
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.brandText)
                    Text(label)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.brandTextDim)
                }
                .frame(maxWidth: .infinity)
                .padding(10)
                .background(Color.brandSurface)
                .cornerRadius(8)
            }
        }
    }

    private func hitRateRow(_ rates: [Int?]) -> some View {
        HStack(spacing: 6) {
            Text("L5")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.brandTextDim)
            ForEach(Array(rates.prefix(5).enumerated()), id: \.offset) { _, val in
                Circle()
                    .fill(val == 1 ? Color.brandGreen : val == 0 ? Color.brandBorder2 : Color.brandTextDim.opacity(0.3))
                    .frame(width: 10, height: 10)
            }
        }
        .padding(10)
        .background(Color.brandSurface)
        .cornerRadius(8)
    }

    private func leanColor(_ lean: String) -> Color {
        switch lean.uppercased() {
        case "OVER":  return .brandGreen
        case "UNDER": return .brandRed
        case "HOME":  return .brandGreen
        case "AWAY":  return .brandCyan
        case "NRFI":  return .brandCyan
        case "YRFI":  return .brandAmber
        default:      return .brandTextMuted
        }
    }
}

// MARK: - Signal row
private struct SignalRow: View {
    let signal: ScoreSignal

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Top: label + score
            HStack {
                Text(signal.label)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundColor(.brandText)
                Spacer()
                Text(signal.scoreLabel)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(signal.barColor)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.brandBorder2)
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(signal.barColor)
                        .frame(width: geo.size.width * signal.fillFraction, height: 4)
                }
            }
            .frame(height: 6)

            // Bottom: value + description
            HStack {
                if let val = signal.value {
                    Text(val)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.brandTextMuted)
                }
                Spacer()
                if let desc = signal.description {
                    Text(desc)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.brandTextDim)
                        .multilineTextAlignment(.trailing)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
