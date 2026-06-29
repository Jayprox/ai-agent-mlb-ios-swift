import SwiftUI

struct BoardCandidateCardView: View {
    let rank: Int
    let candidate: BoardCandidate
    let fallbackOdds: OddsData?
    @EnvironmentObject var picksVM: PicksViewModel
    @EnvironmentObject var auth: AuthViewModel
    @State private var showWhy = false
    @State private var showLogPick = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MARK: - Top row: rank / score / SIM / result
            HStack(alignment: .center, spacing: 10) {
                // Rank
                Text("\(rank)")
                    .scaledFont(size: 11, weight: .bold, design: .monospaced)
                    .foregroundColor(.brandTextDim)
                    .frame(width: 20)

                // Score bubble
                Text("\(candidate.score)")
                    .scaledFont(size: 13, weight: .bold, design: .monospaced)
                    .foregroundColor(candidate.scoreColor)
                    .frame(width: 32, height: 32)
                    .background(candidate.scoreColor.opacity(0.12))
                    .clipShape(Circle())

                // SIM
                if let sim = candidate.simConfidence {
                    Text("\(sim)%")
                        .scaledFont(size: 10, design: .monospaced)
                        .foregroundColor(.brandPurple)
                        + Text(" SIM")
                        .scaledFont(size: 9, design: .monospaced)
                        .foregroundColor(.brandTextDim)
                }

                Spacer()

                // Result badge
                resultBadge
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)

            // MARK: - Name + market + team + handedness
            HStack(spacing: 6) {
                Text(candidate.displayName)
                    .scaledFont(size: 14, weight: .bold, design: .monospaced)
                    .foregroundColor(.brandText)
                MarketBadge(market: candidate.market)
                if let team = candidate.team {
                    Text(team)
                        .scaledFont(size: 11, design: .monospaced)
                        .foregroundColor(.brandTextMuted)
                }
                if let hand = candidate.handLabel {
                    Text(hand)
                        .scaledFont(size: 9, weight: .medium, design: .monospaced)
                        .foregroundColor(.brandTextDim)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 6)

            // MARK: - Game label (skip if same as displayName to avoid duplication)
            if candidate.displayGameLabel != candidate.displayName {
                HStack(spacing: 8) {
                    Text(candidate.displayGameLabel)
                        .scaledFont(size: 11, design: .monospaced)
                        .foregroundColor(.brandTextDim)

                    // Game time + LIVE badge
                    if !candidate.formattedGameTime.isEmpty {
                        Text(candidate.formattedGameTime)
                            .scaledFont(size: 10, design: .monospaced)
                            .foregroundColor(.brandTextMuted)

                        if candidate.isLive {
                            HStack(spacing: 3) {
                                Circle()
                                    .fill(Color.brandRed)
                                    .frame(width: 5, height: 5)
                                Text("LIVE")
                                    .scaledFont(size: 9, weight: .bold, design: .monospaced)
                                    .foregroundColor(.brandRed)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.brandRed.opacity(0.12))
                            .cornerRadius(4)
                        }
                    }

                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.top, 2)
            }

            // MARK: - Weather / park-factor badge (game markets only)
            if let weatherParkLabel = candidate.weatherParkLabel {
                Text(weatherParkLabel)
                    .scaledFont(size: 10, weight: .semibold, design: .monospaced)
                    .foregroundColor(candidate.weatherParkColor)
                    .padding(.horizontal, 14)
                    .padding(.top, 4)
            }

            // MARK: - AI summary (expanded to show full text)
            if let summary = candidate.boardSummary, !summary.isEmpty {
                Text(summary)
                    .scaledFont(size: 11, design: .monospaced)
                    .foregroundColor(.brandTextMuted)
                    .padding(.horizontal, 14)
                    .padding(.top, 4)
            }

            // MARK: - Stats row
            if candidate.isPitcherMarket {
                pitcherStats
            } else if candidate.isBatterMarket {
                batterStats
            }

            // MARK: - Signals chips
            if let signals = candidate.signals, !signals.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(signals, id: \.self) { signal in
                            Text(signal)
                                .scaledFont(size: 9, weight: .medium, design: .monospaced)
                                .foregroundColor(.brandTextMuted)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.brandSurface2)
                                .cornerRadius(4)
                        }
                    }
                    .padding(.horizontal, 14)
                }
                .padding(.top, 6)
            }

            // MARK: - Multi-book odds chips (Total/Spread/ML/F5 — not NRFI)
            if candidate.isGameMarket, candidate.market.lowercased() != "nrfi",
               let books = candidate.odds?.books, !books.isEmpty {
                bookChipsRow(books)
                    .padding(.top, 8)
            }

            Divider()
                .background(Color.brandBorder)
                .padding(.top, 8)

            // MARK: - Lean + line + odds + book + Why button
            HStack(spacing: 0) {
                // Lean
                if !candidate.displayLean.isEmpty {
                    Text(candidate.displayLean)
                        .scaledFont(size: 12, weight: .bold, design: .monospaced)
                        .foregroundColor(leanColor(candidate.leanColorBasis))
                        .padding(.leading, 14)
                }

                if candidate.isGameMarket {
                    // Line (Spread/Total/F5 RL — nil for ML/F5 ML/NRFI)
                    if let line = gameLineLabel {
                        Text(" \(line)")
                            .scaledFont(size: 12, weight: .semibold, design: .monospaced)
                            .foregroundColor(.brandText)
                    }

                    // Odds (lean side, best book)
                    if let o = gameOddsLabel {
                        Text(" (\(o))")
                            .scaledFont(size: 11, design: .monospaced)
                            .foregroundColor(.brandTextDim)
                    }

                    // Best book — only shown alongside an actual line/odds value
                    // (e.g. omitted on NRFI, which has neither)
                    if let book = gameBookLabel,
                       gameLineLabel != nil || gameOddsLabel != nil {
                        Text(" · \(book)")
                            .scaledFont(size: 9, weight: .medium, design: .monospaced)
                            .foregroundColor(.brandTextDim)
                    }
                } else {
                    // Book line
                    if let lineLabel = propLineLabel {
                        Text(" \(lineLabel)")
                            .scaledFont(size: 12, weight: .semibold, design: .monospaced)
                            .foregroundColor(.brandText)
                    }

                    // Odds
                    let odds = candidate.displayLean.uppercased() == "UNDER" ? candidate.underOdds : candidate.overOdds
                    if let o = odds {
                        Text(" (\(o))")
                            .scaledFont(size: 11, design: .monospaced)
                            .foregroundColor(.brandTextDim)
                    }

                    // Book
                    if let book = candidate.bestBook {
                        Text(" · \(book)")
                            .scaledFont(size: 9, weight: .medium, design: .monospaced)
                            .foregroundColor(.brandTextDim)
                    }
                }

                Spacer()

                // Why? button
                Button {
                    HapticManager.light()
                    showWhy = true
                } label: {
                    HStack(spacing: 4) {
                        Text("why?")
                            .scaledFont(size: 11, design: .monospaced)
                            .foregroundColor(.brandTextDim)
                        Image(systemName: "chevron.right")
                            .scaledFont(size: 9)
                            .foregroundColor(.brandTextDim)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                }

                // + Log pick button
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
            .padding(.bottom, 2)
        }
        .background(Color.brandSurface)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(borderColor, lineWidth: 1)
        )
        .sheet(isPresented: $showWhy) {
            WhyModalView(candidate: candidate, rank: rank)
        }
        .sheet(isPresented: $showLogPick) {
            LogPickSheet(vm: picksVM, prefill: candidatePrefill)
                .presentationDetents([.large])
        }
    }

    private var candidatePrefill: LogPickPrefill {
        let resolvedBookLine: Double?
        let resolvedOdds: String?

        if candidate.isGameMarket {
            if let lineStr = candidate.gameDisplayLine {
                // Total / Spread / F5 RL — the displayed line is the book line.
                resolvedBookLine = Double(lineStr.replacingOccurrences(of: "+", with: ""))
                resolvedOdds = candidate.gameDisplayOdds
            } else if let oddsStr = candidate.gameDisplayOdds {
                // ML / F5 ML — there's no separate "line"; the moneyline price
                // itself is the value being logged.
                resolvedBookLine = Double(oddsStr.replacingOccurrences(of: "+", with: ""))
                resolvedOdds = nil
            } else {
                // NRFI — no numeric line/odds available; leave for manual entry.
                resolvedBookLine = nil
                resolvedOdds = nil
            }
        } else {
            resolvedBookLine = candidate.bookLine
            resolvedOdds = candidate.overOdds
        }

        return LogPickPrefill(
            playerName: candidate.displayName,
            market: candidate.market,
            // Use the raw lean (HOME/AWAY/OVER/UNDER/NRFI/YRFI) here, not
            // `displayLean` — for Spread/ML/F5 markets `displayLean` shows a
            // team abbreviation (e.g. "CHC"), which doesn't match any of
            // LogPickSheet's SIDE picker options and renders blank.
            side: (candidate.lean ?? "").isEmpty ? "OVER" : candidate.lean!.uppercased(),
            bookLine: resolvedBookLine,
            odds: resolvedOdds,
            gameLabel: candidate.displayGameLabel,
            // Game-market picks (ml/spread/total/nrfi/f5ml/f5spread) have no
            // `rawId` (no individual player) — the backend's pick schema
            // stores the gamePk in the `playerId` slot for these markets
            // (see CODEX-HANDOFF.md grading notes), and requires a non-nil
            // value to accept the POST. Without this, submitting a game-market
            // pick fails with "playerId, market, side, slateDate required".
            playerId: candidate.rawId ?? candidate.gamePk
        )
    }

    // MARK: - Pitcher stats
    private var pitcherStats: some View {
        HStack(spacing: 12) {
            if let era  = candidate.era   { statPill("ERA",   era)  }
            if let k9   = candidate.k9    { statPill("K/9",   k9)   }
            if let whip = candidate.whip  { statPill("WHIP",  whip) }
            if let ip   = candidate.avgIP { statPill("IP/gs", ip)   }
            if let k3   = candidate.avgK3 { statPill("AvgK3", k3)   }
        }
        .padding(.horizontal, 14)
        .padding(.top, 6)
    }

    // MARK: - Batter stats
    private var batterStats: some View {
        HStack(spacing: 12) {
            if let avg = candidate.avg {
                statPill("AVG", avg)
            }
            if let ops = candidate.ops {
                statPill("OPS", ops)
            }
            if let hr = candidate.hitRate {
                HStack(spacing: 3) {
                    Text("L5")
                        .scaledFont(size: 9, design: .monospaced)
                        .foregroundColor(.brandTextDim)
                    ForEach(Array(hr.prefix(5).enumerated()), id: \.offset) { _, val in
                        Circle()
                            .fill(val == 1 ? Color.brandGreen : val == 0 ? Color.brandBorder2 : Color.brandTextDim.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 6)
    }

    // MARK: - Book odds chips
    /// Display order for book chips (matches Settings preferredBook codes).
    private static let bookOrder = ["DK", "FD", "CZR", "MGM"]

    private func bookChipsRow(_ books: [String: BookLines]) -> some View {
        let chips: [(code: String, text: String)] = Self.bookOrder.compactMap { code in
            guard let lines = books[code], let text = chipText(lines) else { return nil }
            return (code, text)
        }
        guard !chips.isEmpty else { return AnyView(EmptyView()) }

        return AnyView(
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(chips, id: \.code) { chip in
                        let isPreferred = chip.code == auth.preferredBook
                        HStack(spacing: 3) {
                            if isPreferred {
                                Text("★")
                                    .scaledFont(size: 8)
                                    .foregroundColor(.brandAmber)
                            }
                            Text(chip.code)
                                .scaledFont(size: 9, weight: .bold, design: .monospaced)
                                .foregroundColor(.brandTextDim)
                            Text(chip.text)
                                .scaledFont(size: 10, weight: .semibold, design: .monospaced)
                                .foregroundColor(.brandText)
                        }
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(isPreferred ? Color.brandAmber.opacity(0.10) : Color.brandSurface2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(isPreferred ? Color.brandAmber.opacity(0.4) : Color.clear, lineWidth: 1)
                        )
                        .cornerRadius(5)
                    }
                }
                .padding(.horizontal, 14)
            }
        )
    }

    private var gameLineLabel: String? {
        if let line = candidate.gameDisplayLine, !line.isEmpty, line != "—" {
            return line
        }
        guard let fallbackOdds else { return nil }
        switch candidate.market.lowercased() {
        case "total":
            return fallbackOdds.total
        case "spread", "f5spread":
            return candidate.leanIsHome ? fallbackOdds.homeSpread : fallbackOdds.awaySpread
        default:
            return nil
        }
    }

    private var gameOddsLabel: String? {
        if let odds = candidate.gameDisplayOdds, !odds.isEmpty, odds != "—" {
            return odds
        }
        guard let fallbackOdds else { return nil }
        switch candidate.market.lowercased() {
        case "total":
            return candidate.leanIsUnder ? fallbackOdds.underOdds : fallbackOdds.overOdds
        case "spread", "f5spread":
            return candidate.leanIsHome ? fallbackOdds.homeSpreadOdds : fallbackOdds.awaySpreadOdds
        default:
            return nil
        }
    }

    private var gameBookLabel: String? {
        if let book = candidate.gameBestBook, !book.isEmpty {
            return book
        }
        return fallbackOdds?.book
    }

    private var propLineLabel: String? {
        guard let line = candidate.bookLine else { return nil }
        let formattedLine = line == line.rounded() ? "\(Int(line))" : String(format: "%.1f", line)

        switch candidate.market.lowercased() {
        case "k":
            return "O/U \(formattedLine)"
        case "outs":
            return "O/U \(formattedLine) outs"
        default:
            return formattedLine
        }
    }

    /// Builds the chip label for a single book's lines, based on market type
    /// and the candidate's lean (HOME/AWAY for Spread/ML, OVER/UNDER for Total).
    /// - Total: "{line} {odds}" (e.g. "8.5 -110")
    /// - Spread/F5 RL: "{line} {odds}" (e.g. "-1.5 +120") — line already signed by API
    /// - ML/F5 ML: "{odds}" only (no separate numeric line)
    private func chipText(_ b: BookLines) -> String? {
        let leanIsHome  = candidate.leanIsHome
        let leanIsUnder = candidate.leanIsUnder
        switch candidate.market.lowercased() {
        case "ml":
            return leanIsHome ? b.homeML : b.awayML
        case "f5ml":
            // F5-specific ML odds are currently always null from the odds
            // provider — fall back to the full-game ML (labeled "F5"),
            // matching the web app.
            return (leanIsHome ? b.f5HomeML : b.f5AwayML) ?? (leanIsHome ? b.homeML : b.awayML)
        case "total":
            let oddsValue = leanIsUnder ? b.underOdds : b.overOdds
            guard let lineStr = b.total else { return oddsValue }
            if let o = oddsValue { return "\(lineStr) \(o)" }
            return lineStr
        case "spread":
            let lineStr  = leanIsHome ? b.homeSpread : b.awaySpread
            let oddsStr  = leanIsHome ? b.homeSpreadOdds : b.awaySpreadOdds
            if let l = lineStr, let o = oddsStr { return "\(l) \(o)" }
            return lineStr ?? oddsStr
        case "f5spread":
            // F5-specific run-line odds are currently always null from the
            // odds provider — fall back to the full-game spread (labeled
            // "F5"), matching the web app.
            let lineStr  = (leanIsHome ? b.f5HomeSpread : b.f5AwaySpread) ?? (leanIsHome ? b.homeSpread : b.awaySpread)
            let oddsStr  = (leanIsHome ? b.f5HomeSpreadOdds : b.f5AwaySpreadOdds) ?? (leanIsHome ? b.homeSpreadOdds : b.awaySpreadOdds)
            if let l = lineStr, let o = oddsStr { return "\(l) \(o)" }
            return lineStr ?? oddsStr
        default:
            return nil
        }
    }

    // MARK: - Helpers
    private func statPill(_ label: String, _ value: String) -> some View {
        VStack(spacing: 1) {
            Text(value)
                .scaledFont(size: 12, weight: .semibold, design: .monospaced)
                .foregroundColor(.brandText)
            Text(label)
                .scaledFont(size: 9, design: .monospaced)
                .foregroundColor(.brandTextDim)
        }
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

    private var borderColor: Color {
        if candidate.gradeIsHit == true  { return .brandGreen.opacity(0.3) }
        if candidate.gradeIsHit == false { return .brandRed.opacity(0.2) }
        return .brandBorder
    }

    @ViewBuilder
    private var resultBadge: some View {
        if let gradeStatus = candidate.gradeStatus {
            Text(gradeStatus.uppercased())
                .scaledFont(size: 9, weight: .bold, design: .monospaced)
                .foregroundColor(.brandAmber)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.brandAmber.opacity(0.12))
                .cornerRadius(4)
        } else if let hit = candidate.resultHit {
            Text(hit ? "HIT ✓" : "MISS ✗")
                .scaledFont(size: 9, weight: .bold, design: .monospaced)
                .foregroundColor(hit ? .brandGreen : .brandRed)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background((hit ? Color.brandGreen : Color.brandRed).opacity(0.12))
                .cornerRadius(4)
        }
    }
}
