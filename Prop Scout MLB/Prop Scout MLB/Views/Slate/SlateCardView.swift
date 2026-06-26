import SwiftUI

struct SlateCardView: View {
    let game: SlateGame
    let odds: OddsData?
    let nrfi: NRFIData?
    let weather: WeatherData?
    let linescore: LinescoreData?
    var kHint: String? = nil
    var awayPitcherEra: String? = nil
    var homePitcherEra: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MARK: - Header: Teams + Score/Status
            HStack(alignment: .center, spacing: 0) {
                // Away team
                VStack(spacing: 2) {
                    Text(game.away.abbr)
                        .scaledFont(size: 22, weight: .bold, design: .monospaced)
                        .foregroundColor(.brandText)
                    if let ls = linescore, (game.isFinal || game.isLive || ls.inning > 0) {
                        Text("\(ls.awayScore)")
                            .scaledFont(size: 18, weight: .bold, design: .monospaced)
                            .foregroundColor(ls.awayScore > ls.homeScore ? .brandText : .brandTextMuted)
                    }
                }
                .frame(maxWidth: .infinity)

                // Center: @ + status
                VStack(spacing: 4) {
                    statusBadge
                    if game.isLive, let ls = linescore {
                        // Inning + outs (e.g. "▲10 · 2 out")
                        let outsLabel = ls.outs.map { o in o == 1 ? "1 out" : "\(o) outs" } ?? ""
                        Text([game.inningLabel(linescore: ls), outsLabel]
                            .filter { !$0.isEmpty }
                            .joined(separator: " · "))
                            .scaledFont(size: 11, weight: .semibold, design: .monospaced)
                            .foregroundColor(.brandTextMuted)
                    } else if game.isUpcoming {
                        Text(game.formattedTime)
                            .scaledFont(size: 11, weight: .medium, design: .monospaced)
                            .foregroundColor(.brandTextMuted)
                    }
                    Text("@")
                        .scaledFont(size: 13, weight: .medium)
                        .foregroundColor(.brandTextDim)
                }
                .frame(maxWidth: .infinity)

                // Home team
                VStack(spacing: 2) {
                    Text(game.home.abbr)
                        .scaledFont(size: 22, weight: .bold, design: .monospaced)
                        .foregroundColor(.brandText)
                    if let ls = linescore, (game.isFinal || game.isLive || ls.inning > 0) {
                        Text("\(ls.homeScore)")
                            .scaledFont(size: 18, weight: .bold, design: .monospaced)
                            .foregroundColor(ls.homeScore > ls.awayScore ? .brandText : .brandTextMuted)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            Divider().background(Color.brandBorder)

            // MARK: - Info row: time + venue
            VStack(alignment: .leading, spacing: 2) {
                // Game time + venue
                Text(venueTimeText)
                    .scaledFont(size: 10, design: .monospaced)
                    .foregroundColor(.brandTextMuted)

                // Starting pitchers
                if let pp = game.probablePitchers {
                    HStack(spacing: 4) {
                        Text("SP")
                            .scaledFont(size: 10, weight: .bold, design: .monospaced)
                            .foregroundColor(.brandTextDim)

                        if let away = pp.away {
                            HStack(spacing: 2) {
                                Text(away.name.components(separatedBy: " ").last ?? away.name)
                                    .scaledFont(size: 11, design: .monospaced)
                                    .foregroundColor(away.isIL == true ? .brandTextDim : .brandTextMuted)
                                if let hand = away.hand {
                                    Text(hand)
                                        .scaledFont(size: 10, weight: .bold, design: .monospaced)
                                        .foregroundColor(.brandTextDim)
                                }
                                if game.isUpcoming, let era = awayPitcherEra, !era.isEmpty {
                                    Text("ERA \(era)")
                                        .scaledFont(size: 10, design: .monospaced)
                                        .foregroundColor(.brandTextDim)
                                }
                            }
                            if away.isIL == true {
                                ILBadge()
                            }
                        }

                        Text("vs")
                            .scaledFont(size: 10, design: .monospaced)
                            .foregroundColor(.brandTextDim)

                        if let home = pp.home {
                            HStack(spacing: 2) {
                                Text(home.name.components(separatedBy: " ").last ?? home.name)
                                    .scaledFont(size: 11, design: .monospaced)
                                    .foregroundColor(home.isIL == true ? .brandTextDim : .brandTextMuted)
                                if let hand = home.hand {
                                    Text(hand)
                                        .scaledFont(size: 10, weight: .bold, design: .monospaced)
                                        .foregroundColor(.brandTextDim)
                                }
                                if game.isUpcoming, let era = homePitcherEra, !era.isEmpty {
                                    Text("ERA \(era)")
                                        .scaledFont(size: 10, design: .monospaced)
                                        .foregroundColor(.brandTextDim)
                                }
                            }
                            if home.isIL == true {
                                ILBadge()
                            }
                        }
                    }

                    // K OVER hint chip
                    if let hint = kHint {
                        HStack(spacing: 4) {
                            Image(systemName: "bolt.fill")
                                .scaledFont(size: 8)
                            Text(hint)
                                .scaledFont(size: 10, weight: .semibold, design: .monospaced)
                        }
                        .foregroundColor(.marketK)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.marketK.opacity(0.12))
                        .cornerRadius(4)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            // MARK: - Odds + Weather rows
            if odds != nil || weather != nil || nrfi != nil {
                Divider().background(Color.brandBorder)

                VStack(alignment: .leading, spacing: 6) {
                    // Row 1: O/U | ML | Weather | NRFI
                    HStack(spacing: 10) {
                        // O/U
                        if let o = odds, let total = o.total {
                            HStack(spacing: 4) {
                                Text("O/U")
                                    .scaledFont(size: 9, weight: .bold, design: .monospaced)
                                    .foregroundColor(.brandTextDim)
                                Text(total)
                                    .scaledFont(size: 11, weight: .semibold, design: .monospaced)
                                    .foregroundColor(.brandText)
                            }
                        }

                        // ML label
                        if let o = odds, let awayML = o.awayML, let homeML = o.homeML {
                            HStack(spacing: 4) {
                                Text("ML")
                                    .scaledFont(size: 9, weight: .bold, design: .monospaced)
                                    .foregroundColor(.brandTextDim)
                                Text("\(awayML) / \(homeML)")
                                    .scaledFont(size: 11, design: .monospaced)
                                    .foregroundColor(.brandTextMuted)
                            }
                        }

                        // Trend chip — "↑ OVER" (green) or "↓ UNDER" (red)
                        if let trend = odds?.trend {
                            let isOver = trend.uppercased() == "OVER"
                            HStack(spacing: 2) {
                                Text(isOver ? "↑" : "↓")
                                Text(trend.uppercased())
                            }
                            .scaledFont(size: 9, weight: .bold, design: .monospaced)
                            .foregroundColor(isOver ? .brandGreen : .brandRed)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background((isOver ? Color.brandGreen : Color.brandRed).opacity(0.15))
                            .cornerRadius(4)
                        }

                        Spacer()

                        // Weather + Wind
                        if let w = weather {
                            if w.isDome == true {
                                Text("DOME")
                                    .scaledFont(size: 10, weight: .semibold, design: .monospaced)
                                    .foregroundColor(.brandTextDim)
                            } else {
                                VStack(alignment: .trailing, spacing: 1) {
                                    Text(w.tempString)
                                        .scaledFont(size: 11, design: .monospaced)
                                        .foregroundColor(.brandTextMuted)
                                    if let speed = w.windspeed, let dir = w.winddirection {
                                        let windDir = compassLabel(for: dir)
                                        Text("\(Int(speed))mph \(windDir)")
                                            .scaledFont(size: 8, design: .monospaced)
                                            .foregroundColor(.brandTextDim)
                                            .lineLimit(1)
                                    }
                                }
                            }
                        }

                        // NRFI lean
                        if let n = nrfi, let lean = n.lean {
                            NRFILeanBadge(lean: lean, confidence: n.confidence, reason: n.reason)
                        }
                    }

                    // Row 2: RL (run line)
                    if let o = odds,
                       let awaySpread = o.awaySpread, let homeSpread = o.homeSpread {
                        HStack(spacing: 4) {
                            Text("RL")
                                .scaledFont(size: 9, weight: .bold, design: .monospaced)
                                .foregroundColor(.brandTextDim)
                            // Away spread + odds
                            Group {
                                Text(awaySpread)
                                if let aOdds = o.awaySpreadOdds {
                                    Text("(\(aOdds))")
                                        .foregroundColor(.brandTextDim)
                                }
                            }
                            .scaledFont(size: 11, design: .monospaced)
                            .foregroundColor(.brandTextMuted)

                            Text("/")
                                .scaledFont(size: 10, design: .monospaced)
                                .foregroundColor(.brandTextDim)

                            // Home spread + odds
                            Group {
                                Text(homeSpread)
                                if let hOdds = o.homeSpreadOdds {
                                    Text("(\(hOdds))")
                                        .foregroundColor(.brandTextDim)
                                }
                            }
                            .scaledFont(size: 11, design: .monospaced)
                            .foregroundColor(.brandTextMuted)

                            if let book = o.book {
                                Spacer()
                                Text(book)
                                    .scaledFont(size: 9, design: .monospaced)
                                    .foregroundColor(.brandTextDim)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
        }
        .background(Color.brandSurface)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(game.isLive ? Color.brandRed.opacity(0.3) : Color.brandBorder, lineWidth: 1)
        )
    }

    // MARK: - Venue + time helper
    private var venueTimeText: String {
        let parts = [game.formattedTime, game.venue]
            .map { ($0 ?? "").trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return parts.joined(separator: " · ")
    }

    // MARK: - Status badge
    @ViewBuilder
    private var statusBadge: some View {
        if game.isLive && (linescore?.inning ?? 0) > 0 {
            LiveBadge()
        } else if game.isFinal {
            FinalBadge()
        } else if game.isPPD {
            PPDBadge()
        }
    }

    // MARK: - Compass direction (shortened to 1 letter)
    private func compassLabel(for degrees: Double) -> String {
        let dirs = ["N","NNE","NE","ENE","E","ESE","SE","SSE","S","SSW","SW","WSW","W","WNW","NW","NNW"]
        let index = Int((degrees / 22.5).rounded()) % 16
        let fullDir = dirs[max(0, min(15, index))]
        return String(fullDir.first ?? "N")  // Return just first letter
    }

}
