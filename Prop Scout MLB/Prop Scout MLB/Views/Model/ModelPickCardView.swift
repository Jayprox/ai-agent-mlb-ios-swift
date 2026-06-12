import SwiftUI

struct ModelPickCardView: View {
    let edge: AIBoardEdge
    @EnvironmentObject var picksVM: PicksViewModel
    @State private var showLogPick = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // MARK: - Matchup + badges
            HStack(spacing: 6) {
                Text(edge.displayGameLabel)
                    .scaledFont(size: 11, weight: .semibold, design: .monospaced)
                    .foregroundColor(.brandTextDim)
                badge("ALGORITHMIC", color: .brandCyan)
                if verifiedBookCount >= 2 {
                    badge("✓ VERIFIED", color: .brandGreen)
                }
                Spacer()
                resultBadge
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)

            // MARK: - Title row: name + market O/U line  /  book + lean + sim%
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(titleText)
                        .scaledFont(size: 14, weight: .bold, design: .monospaced)
                        .foregroundColor(.brandText)
                    if let team = edge.team {
                        Text(team)
                            .scaledFont(size: 10, design: .monospaced)
                            .foregroundColor(.brandTextMuted)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    if let book = edge.bestBookLabel {
                        Text(book)
                            .scaledFont(size: 9, weight: .bold, design: .monospaced)
                            .foregroundColor(.brandTextDim)
                            .kerning(0.5)
                    }
                    HStack(spacing: 4) {
                        Text(leanLabel)
                            .foregroundColor(leanLabel == "OVER" ? .brandGreen : .brandRed)
                        if let sim = edge.simConfidence {
                            Text("\(sim)%")
                                .foregroundColor(.brandPurple)
                        }
                    }
                    .scaledFont(size: 12, weight: .bold, design: .monospaced)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 8)

            // MARK: - LINES row
            if !edge.bookChips.isEmpty || edge.projectedLine != nil {
                VStack(alignment: .leading, spacing: 6) {
                    Text("LINES")
                        .scaledFont(size: 9, weight: .bold, design: .monospaced)
                        .foregroundColor(.brandTextDim)
                        .kerning(1)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(edge.bookChips, id: \.book) { chip in
                                lineChip(chip)
                            }
                            if let proj = edge.projectedLine {
                                projectionBadge(proj)
                            }
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 10)
            }

            // MARK: - Verified market line
            if let verified = verifiedMarketText {
                HStack(spacing: 4) {
                    Text("✓")
                        .foregroundColor(.brandGreen)
                    Text(verified)
                        .foregroundColor(.brandTextMuted)
                }
                .scaledFont(size: 10, design: .monospaced)
                .padding(.horizontal, 14)
                .padding(.top, 8)
            }

            // MARK: - Analysis
            if let reason = edge.aiReason, !reason.isEmpty {
                Text(reason)
                    .scaledFont(size: 11, design: .monospaced)
                    .italic()
                    .foregroundColor(.brandTextMuted)
                    .lineSpacing(3)
                    .padding(.horizontal, 14)
                    .padding(.top, 8)
            }

            // MARK: - Factor bullets
            let signals = edge.factorSignals
            if !signals.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(signals) { sig in
                        HStack(alignment: .top, spacing: 4) {
                            Text("·")
                            Text(factorText(sig))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .scaledFont(size: 10, design: .monospaced)
                        .foregroundColor(.brandTextDim)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 8)
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

    private var leanLabel: String { (edge.lean ?? "OVER").uppercased() }

    private var titleText: String {
        var s = "\(edge.displayName) \(edge.pickMarketLabel) O/U"
        if let line = edge.pickBookLine {
            s += " \(fmt(line))"
        }
        return s
    }

    private var verifiedBookCount: Int {
        edge.candidate?.propLine?.books?.count ?? 0
    }

    private var verifiedMarketText: String? {
        let n = verifiedBookCount
        guard n > 0 else { return nil }
        var s = "Verified Market · \(n) book\(n == 1 ? "" : "s")"
        if let book = edge.bestBookLabel, let odds = edge.bestBookOdds {
            s += " · Best: \(book) \(odds)"
        }
        return s
    }

    // MARK: - Subviews

    private func lineChip(_ chip: (book: String, line: Double?, odds: String?)) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 3) {
                if chip.book == edge.bestBookLabel {
                    Text("★")
                        .foregroundColor(.brandAmber)
                }
                Text(chip.book)
                    .foregroundColor(.brandText)
            }
            .scaledFont(size: 10, weight: .bold, design: .monospaced)

            Text(chip.line.map(fmt) ?? "—")
                .scaledFont(size: 11, weight: .semibold, design: .monospaced)
                .foregroundColor(.brandText)

            if let odds = chip.odds {
                Text(odds)
                    .scaledFont(size: 9, design: .monospaced)
                    .foregroundColor(.brandTextMuted)
            }
        }
        .frame(width: 52)
        .padding(.vertical, 6)
        .background(Color.brandSurface2)
        .cornerRadius(6)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.brandBorder, lineWidth: 1))
    }

    private func projectionBadge(_ value: Double) -> some View {
        VStack(spacing: 2) {
            Text("PROJECTION")
                .scaledFont(size: 8, weight: .bold, design: .monospaced)
                .foregroundColor(.brandTextDim)
                .kerning(0.5)
            Text("Est. \(fmt(value))")
                .scaledFont(size: 11, weight: .bold, design: .monospaced)
                .foregroundColor(.brandAmber)
        }
        .frame(width: 64)
        .padding(.vertical, 6)
        .background(Color.brandAmber.opacity(0.10))
        .cornerRadius(6)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.brandAmber.opacity(0.35), lineWidth: 1))
    }

    private func factorText(_ sig: ScoreSignal) -> String {
        var parts: [String] = [sig.label]
        if let value = sig.value, !value.isEmpty {
            parts.append(value)
        }
        if let desc = sig.description, !desc.isEmpty {
            return "\(parts.joined(separator: " ")) — \(desc)"
        }
        return parts.joined(separator: " ")
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

    private func fmt(_ v: Double) -> String {
        v == v.rounded() ? "\(Int(v))" : String(format: "%.1f", v)
    }

    private var edgePrefill: LogPickPrefill {
        LogPickPrefill(
            playerName: edge.displayName,
            market: edge.market ?? "",
            side: edge.lean ?? "OVER",
            bookLine: edge.pickBookLine ?? edge.bookLine,
            odds: edge.bestBookOdds,
            gameLabel: edge.displayGameLabel,
            playerId: edge.rawId.flatMap { Int($0) }
        )
    }
}
