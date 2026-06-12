import SwiftUI

struct AIBoardEdgeCardView: View {
    let rank: Int
    let edge: AIBoardEdge
    @EnvironmentObject var picksVM: PicksViewModel
    @State private var showLogPick = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // MARK: - Top row: rank / AI score / ALG / SIM / result
            HStack(alignment: .center, spacing: 10) {
                Text("\(rank)")
                    .scaledFont(size: 11, weight: .bold, design: .monospaced)
                    .foregroundColor(.brandTextDim)
                    .frame(width: 20)

                // AI score bubble
                VStack(spacing: 1) {
                    Text("\(edge.aiScore)")
                        .scaledFont(size: 14, weight: .bold, design: .monospaced)
                        .foregroundColor(edge.aiScoreColor)
                    Text("AI")
                        .scaledFont(size: 8, design: .monospaced)
                        .foregroundColor(.brandTextDim)
                }
                .frame(width: 36, height: 36)
                .background(edge.aiScoreColor.opacity(0.12))
                .clipShape(Circle())

                // ALG score
                if let alg = edge.score {
                    VStack(spacing: 1) {
                        Text("\(alg)")
                            .scaledFont(size: 11, weight: .semibold, design: .monospaced)
                            .foregroundColor(edge.algScoreColor)
                        Text("ALG")
                            .scaledFont(size: 8, design: .monospaced)
                            .foregroundColor(.brandTextDim)
                    }
                }

                // SIM confidence
                if let sim = edge.simConfidence {
                    Text("\(sim)%")
                        .scaledFont(size: 10, design: .monospaced)
                        .foregroundColor(.brandPurple)
                    + Text(" SIM")
                        .scaledFont(size: 9, design: .monospaced)
                        .foregroundColor(.brandTextDim)
                }

                Spacer()
                resultBadge
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)

            // MARK: - Name + market + team
            HStack(spacing: 6) {
                Text(edge.displayName)
                    .scaledFont(size: 14, weight: .bold, design: .monospaced)
                    .foregroundColor(.brandText)
                MarketBadge(market: edge.market ?? "")
                if let team = edge.team {
                    Text(team)
                        .scaledFont(size: 11, design: .monospaced)
                        .foregroundColor(.brandTextMuted)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 6)

            // MARK: - Game label
            Text(edge.displayGameLabel)
                .scaledFont(size: 11, design: .monospaced)
                .foregroundColor(.brandTextDim)
                .padding(.horizontal, 14)
                .padding(.top, 2)

            // MARK: - AI reasoning
            if let reason = edge.aiReason, !reason.isEmpty {
                Text(reason)
                    .scaledFont(size: 11, design: .monospaced)
                    .foregroundColor(.brandTextMuted)
                    .lineSpacing(3)
                    .padding(.horizontal, 14)
                    .padding(.top, 8)
            }

            Divider()
                .background(Color.brandBorder)
                .padding(.top, 10)

            // MARK: - Bottom: lean + line + edge
            HStack(spacing: 0) {
                if let lean = edge.lean, !lean.isEmpty {
                    Text(lean.uppercased())
                        .scaledFont(size: 12, weight: .bold, design: .monospaced)
                        .foregroundColor(lean.uppercased() == "OVER" ? .brandGreen : .brandRed)
                        .padding(.horizontal, 14)
                }

                if let line = edge.bookLine {
                    Text(line == line.rounded() ? "\(Int(line))" : String(format: "%.1f", line))
                        .scaledFont(size: 12, weight: .semibold, design: .monospaced)
                        .foregroundColor(.brandText)
                }

                if let e = edge.edge {
                    Text("  edge +\(String(format: "%.0f", e * 100))%")
                        .scaledFont(size: 10, design: .monospaced)
                        .foregroundColor(.brandAmber)
                }

                Spacer()

                Button {
                    HapticManager.light()
                    showLogPick = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .scaledFont(size: 20)
                        .foregroundColor(.brandGreen)
                        .padding(.trailing, 14)
                        .padding(.vertical, 8)
                        .frame(minWidth: 44, minHeight: 44, alignment: .trailing)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Add to Picks")
            }
            .padding(.bottom, 10)
        }
        .background(Color.brandSurface)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(borderColor, lineWidth: 1)
        )
        .sheet(isPresented: $showLogPick) {
            LogPickSheet(vm: picksVM, prefill: edgePrefill)
                .presentationDetents([.large])
        }
    }

    private var edgePrefill: LogPickPrefill {
        LogPickPrefill(
            playerName: edge.displayName,
            market: edge.market ?? "",
            side: edge.lean ?? "OVER",
            bookLine: edge.bookLine,
            odds: nil,
            gameLabel: edge.displayGameLabel,
            playerId: edge.playerId
        )
    }

    @ViewBuilder
    private var resultBadge: some View {
        if edge.isHit {
            badge("HIT ✓", color: .brandGreen)
        } else if edge.isMiss {
            badge("MISS ✗", color: .brandRed)
        } else if edge.isPPD {
            badge("PPD", color: .brandAmber)
        } else if edge.isScratch {
            badge("SCR", color: .brandAmber)
        }
    }

    private func badge(_ text: String, color: Color) -> some View {
        Text(text)
            .scaledFont(size: 9, weight: .bold, design: .monospaced)
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(color.opacity(0.12))
            .cornerRadius(4)
    }

    private var borderColor: Color {
        if edge.isHit  { return .brandGreen.opacity(0.25) }
        if edge.isMiss { return .brandRed.opacity(0.2) }
        return .brandBorder
    }
}
