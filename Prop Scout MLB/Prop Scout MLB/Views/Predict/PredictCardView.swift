import SwiftUI

struct PredictCardView: View {
    let edge: AIBoardEdge
    @EnvironmentObject var picksVM: PicksViewModel
    @State private var showLogPick = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // MARK: - Name + team + market badges
            HStack(spacing: 6) {
                Text(edge.displayName)
                    .scaledFont(size: 14, weight: .bold, design: .monospaced)
                    .foregroundColor(.brandText)
                if let team = edge.team {
                    teamBadge(team)
                }
                marketBadge
                Spacer()
                resultBadge
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)

            // MARK: - Lean
            Text(leanLabel)
                .scaledFont(size: 12, weight: .bold, design: .monospaced)
                .foregroundColor(leanLabel.hasPrefix("OVER") ? .brandGreen : .brandRed)
                .padding(.horizontal, 14)
                .padding(.top, 6)

            // MARK: - SIM vs BOOK + EDGE
            HStack(alignment: .center, spacing: 10) {
                statBox(value: simText, label: "SIM")
                Text("vs")
                    .scaledFont(size: 11, weight: .semibold, design: .monospaced)
                    .foregroundColor(.brandTextDim)
                statBox(value: bookText, label: "BOOK")
                Spacer()
                edgeBadge
            }
            .padding(.horizontal, 14)
            .padding(.top, 10)

            // MARK: - AI reasoning
            if let reason = edge.aiReason, !reason.isEmpty {
                Text(reason)
                    .scaledFont(size: 11, design: .monospaced)
                    .italic()
                    .foregroundColor(.brandTextMuted)
                    .lineSpacing(3)
                    .padding(.horizontal, 14)
                    .padding(.top, 10)
            }

            Divider()
                .background(Color.brandBorder)
                .padding(.top, 10)

            HStack {
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
            .padding(.bottom, 6)
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

    // MARK: - Derived text

    private var leanLabel: String {
        var text = (edge.lean ?? "OVER").uppercased()
        if let line = edge.pickBookLine ?? edge.bookLine {
            text += " \(fmt(line))"
        }
        return text
    }

    private var simText: String { edge.simPct.map { "\($0)%" } ?? "—" }
    private var bookText: String { edge.bookPct.map { "\($0)%" } ?? "—" }

    private func fmt(_ value: Double) -> String {
        value == value.rounded() ? "\(Int(value))" : String(format: "%.1f", value)
    }

    // MARK: - Subviews

    private func teamBadge(_ team: String) -> some View {
        Text(team)
            .scaledFont(size: 10, weight: .bold, design: .monospaced)
            .foregroundColor(.brandTextMuted)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.brandSurface2)
            .cornerRadius(4)
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.brandBorder, lineWidth: 1))
    }

    private var marketBadge: some View {
        Text(edge.predictMarketLabel)
            .scaledFont(size: 10, weight: .bold, design: .monospaced)
            .foregroundColor(.brandBlue)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.brandBlue.opacity(0.12))
            .cornerRadius(4)
    }

    private func statBox(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .scaledFont(size: 14, weight: .bold, design: .monospaced)
                .foregroundColor(.brandText)
            Text(label)
                .scaledFont(size: 8, weight: .bold, design: .monospaced)
                .foregroundColor(.brandTextDim)
                .kerning(0.5)
        }
        .frame(width: 64)
        .padding(.vertical, 8)
        .background(Color.brandSurface2)
        .cornerRadius(6)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.brandBorder, lineWidth: 1))
    }

    private var edgeBadge: some View {
        let pts = edge.edgePts ?? 0
        let color: Color = pts >= 20 ? .brandGreen : .brandAmber
        return VStack(spacing: 2) {
            Text("+\(pts)pts")
                .scaledFont(size: 13, weight: .bold, design: .monospaced)
                .foregroundColor(color)
            Text("EDGE")
                .scaledFont(size: 8, weight: .bold, design: .monospaced)
                .foregroundColor(.brandTextDim)
                .kerning(0.5)
        }
        .frame(width: 64)
        .padding(.vertical, 8)
        .background(color.opacity(0.10))
        .cornerRadius(6)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(color.opacity(0.35), lineWidth: 1))
    }

    private func badge(_ text: String, color: Color) -> some View {
        Text(text)
            .scaledFont(size: 8, weight: .bold, design: .monospaced)
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(color.opacity(0.12))
            .cornerRadius(4)
            .kerning(0.5)
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

    private var borderColor: Color {
        if edge.isHit  { return .brandGreen.opacity(0.25) }
        if edge.isMiss { return .brandRed.opacity(0.2) }
        return .brandBorder
    }

    private var edgePrefill: LogPickPrefill {
        LogPickPrefill(
            playerName: edge.displayName,
            market: edge.market ?? "",
            side: edge.lean ?? "OVER",
            bookLine: edge.pickBookLine ?? edge.bookLine,
            odds: edge.bestBookOdds,
            gameLabel: edge.displayGameLabel,
            playerId: edge.playerId
        )
    }
}
