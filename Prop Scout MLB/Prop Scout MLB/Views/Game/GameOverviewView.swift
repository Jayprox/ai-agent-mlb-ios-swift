import SwiftUI

struct GameOverviewView: View {
    let game: SlateGame
    @ObservedObject var vm: GameDetailViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                // MARK: - SP toggle
                spToggle
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                // MARK: - Pitcher card
                if let stats = vm.currentStats {
                    pitcherCard(stats: stats, pitcher: selectedPitcher, log: vm.currentGamelog)
                        .padding(.horizontal, 16)
                } else {
                    noDataCard("Pitcher data unavailable")
                        .padding(.horizontal, 16)
                }

                // MARK: - Recent starts
                if let log = vm.currentGamelog, !(log.games?.isEmpty ?? true) {
                    recentStartsCard(log)
                        .padding(.horizontal, 16)
                }

                // MARK: - NRFI
                if let nrfi = vm.nrfi {
                    nrfiCard(nrfi: nrfi)
                        .padding(.horizontal, 16)
                }

                Spacer(minLength: 20)
            }
        }
        .background(Color.brandBackground)
    }

    // MARK: - SP Toggle
    private var spToggle: some View {
        HStack(spacing: 0) {
            spButton(label: "\(game.away.abbr) SP", side: .away)
            spButton(label: "\(game.home.abbr) SP", side: .home)
        }
        .background(Color.brandSurface2)
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.brandBorder, lineWidth: 1))
    }

    private func spButton(label: String, side: GameDetailViewModel.SPSide) -> some View {
        Button {
            vm.selectedSPSide = side
        } label: {
            Text(label)
                .scaledFont(size: 12, weight: .semibold, design: .monospaced)
                .foregroundColor(vm.selectedSPSide == side ? .brandBackground : .brandTextMuted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(vm.selectedSPSide == side ? Color.brandGreen : Color.clear)
                .cornerRadius(7)
        }
    }

    private var selectedPitcher: PitcherInfo? {
        vm.selectedSPSide == .away
            ? game.probablePitchers?.away
            : game.probablePitchers?.home
    }

    // MARK: - Pitcher card
    private func pitcherCard(stats: PitcherStats, pitcher: PitcherInfo?, log: PitcherGamelog?) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Name + team
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(stats.name ?? pitcher?.name ?? "—")
                            .scaledFont(size: 16, weight: .bold, design: .monospaced)
                            .foregroundColor(.brandText)
                        if let pid = pitcher?.id, vm.injuredIds.contains(pid) || pitcher?.isIL == true {
                            ILBadge()
                        }
                        if let hand = pitcher?.hand {
                            Text("\(stats.team ?? "") · SP · \(hand)HP")
                                .scaledFont(size: 10, design: .monospaced)
                                .foregroundColor(.brandTextMuted)
                        }
                    }
                    let opp = vm.selectedSPSide == .away ? "vs \(game.home.abbr)" : "vs \(game.away.abbr)"
                    Text(opp)
                        .scaledFont(size: 11, design: .monospaced)
                        .foregroundColor(.brandTextDim)
                }
                Spacer()
            }

            // Main stats grid
            statGrid([
                ("ERA",    stats.era    ?? "—"),
                ("WHIP",   stats.whip   ?? "—"),
                ("K/9",    stats.kPer9  ?? "—"),
                ("BB/9",   stats.bbPer9 ?? "—"),
                ("AVG IP", log?.avgIP   ?? "—"),
            ])

            // Record
            if let w = stats.wins, let l = stats.losses, let k = stats.k {
                HStack(spacing: 12) {
                    Text("\(w)W–\(l)L")
                        .scaledFont(size: 11, design: .monospaced)
                        .foregroundColor(.brandTextMuted)
                    Text("·")
                        .foregroundColor(.brandTextDim)
                    Text("\(k)K")
                        .scaledFont(size: 11, design: .monospaced)
                        .foregroundColor(.brandTextMuted)
                }
            }

            // vs L/R splits
            if let splits = vm.currentSplits {
                Divider().background(Color.brandBorder)
                HStack(spacing: 12) {
                    splitBlock(label: "VS LHH", avg: splits.vsLeft?.avg, k9: splits.vsLeft?.k9)
                    splitBlock(label: "VS RHH", avg: splits.vsRight?.avg, k9: splits.vsRight?.k9)
                }
            }
        }
        .padding(16)
        .background(Color.brandSurface)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.brandBorder, lineWidth: 1))
    }

    // MARK: - Recent starts
    private func recentStartsCard(_ log: PitcherGamelog) -> some View {
        let games = Array((log.games ?? []).prefix(5))
        let cleanCount = games.filter { ($0.er ?? 1) == 0 }.count

        return VStack(alignment: .leading, spacing: 10) {
            // Header: label + clean starts
            HStack {
                sectionLabel("RECENT STARTS")
                Spacer()
                Text("\(cleanCount)/\(games.count) clean")
                    .scaledFont(size: 10, design: .monospaced)
                    .foregroundColor(cleanCount > 0 ? .brandGreen : .brandTextDim)
            }

            // ERA trend dots
            HStack(spacing: 6) {
                ForEach(games) { g in
                    let er = g.er ?? 0
                    Circle()
                        .fill(er == 0 ? Color.brandGreen : er <= 2 ? Color.brandAmber : Color.brandRed)
                        .frame(width: 10, height: 10)
                    Text("\(er)ER")
                        .scaledFont(size: 9, design: .monospaced)
                        .foregroundColor(.brandTextDim)
                }
            }

            Divider().background(Color.brandBorder)

            // Game log rows
            ForEach(games) { g in
                HStack {
                    Text(g.opponent ?? "—")
                        .scaledFont(size: 11, weight: .semibold, design: .monospaced)
                        .foregroundColor(.brandText)
                        .frame(width: 40, alignment: .leading)
                    Text(formatGameDate(g.date))
                        .scaledFont(size: 10, design: .monospaced)
                        .foregroundColor(.brandTextDim)
                        .frame(width: 44, alignment: .leading)
                    Spacer()
                    Text("\(g.ip ?? "—") IP")
                        .scaledFont(size: 10, design: .monospaced)
                        .foregroundColor(.brandTextMuted)
                    Text("\(g.k ?? 0)K")
                        .scaledFont(size: 10, design: .monospaced)
                        .foregroundColor(.brandCyan)
                        .frame(width: 30)
                    Text("\(g.er ?? 0)ER")
                        .scaledFont(size: 10, design: .monospaced)
                        .foregroundColor((g.er ?? 0) == 0 ? .brandGreen : (g.er ?? 0) <= 2 ? .brandAmber : .brandRed)
                        .frame(width: 30)
                    if let res = g.result {
                        Text(res)
                            .scaledFont(size: 10, weight: .bold, design: .monospaced)
                            .foregroundColor(res == "W" ? .brandGreen : res == "L" ? .brandRed : .brandTextDim)
                            .frame(width: 20)
                    }
                    if let pc = g.pc {
                        Text("\(pc)p")
                            .scaledFont(size: 10, design: .monospaced)
                            .foregroundColor(.brandTextDim)
                            .frame(width: 32, alignment: .trailing)
                    }
                }
            }

            // Last 3 ERA vs season ERA
            let last3ERA = computeLast3ERA(Array(games.prefix(3)))
            if let last3 = last3ERA, let seasonEra = log.seasonEra {
                Divider().background(Color.brandBorder)
                Text("Last 3 ERA: \(last3) vs season \(seasonEra)")
                    .scaledFont(size: 10, design: .monospaced)
                    .foregroundColor(.brandTextMuted)
            }
        }
        .padding(16)
        .background(Color.brandSurface)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.brandBorder, lineWidth: 1))
    }

    /// Parses an ISO date string "YYYY-MM-DD" → "MM/DD"
    private func formatGameDate(_ raw: String?) -> String {
        guard let raw, raw.count >= 10 else { return raw?.prefix(5).description ?? "—" }
        let parts = raw.split(separator: "-")
        guard parts.count >= 3 else { return "—" }
        return "\(parts[1])/\(parts[2])"
    }

    /// Parses baseball IP notation: "5.2" → 5 + 2/3, "6.0" → 6.0
    private func parseIP(_ ip: String?) -> Double {
        guard let s = ip, let dot = s.firstIndex(of: ".") else { return 0 }
        let whole = Double(s[s.startIndex..<dot]) ?? 0
        let outs  = Double(s[s.index(after: dot)...]) ?? 0
        return whole + outs / 3.0
    }

    /// Returns formatted ERA for the given games, or nil if no data.
    private func computeLast3ERA(_ games: [PitcherGameEntry]) -> String? {
        guard !games.isEmpty else { return nil }
        let totalER = Double(games.compactMap { $0.er }.reduce(0, +))
        let totalIP = games.compactMap { $0.ip }.map { parseIP($0) }.reduce(0, +)
        guard totalIP > 0 else { return nil }
        let era = totalER / totalIP * 9.0
        return String(format: "%.2f", era)
    }

    // MARK: - NRFI card
    private func nrfiCard(nrfi: NRFIDetail) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                sectionLabel("FIRST INNING TENDENCIES")
                Spacer()
                if let lean = nrfi.lean, let conf = nrfi.confidence {
                    NRFILeanBadge(lean: lean, confidence: conf)
                }
            }

            HStack(spacing: 12) {
                nrfiTeamBlock(abbr: game.away.abbr, data: nrfi.away)
                nrfiTeamBlock(abbr: game.home.abbr, data: nrfi.home)
            }
        }
        .padding(16)
        .background(Color.brandSurface)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.brandBorder, lineWidth: 1))
    }

    private func nrfiTeamBlock(abbr: String, data: NRFIDetail.NRFITeamData?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(abbr) 1ST INN")
                .scaledFont(size: 10, weight: .bold, design: .monospaced)
                .foregroundColor(.brandTextDim)
            if let pct = data?.scoredPct {
                Text("\(Int((pct * 100).rounded()))%")
                    .scaledFont(size: 20, weight: .bold, design: .monospaced)
                    .foregroundColor(.brandText)
                Text("scored")
                    .scaledFont(size: 10, design: .monospaced)
                    .foregroundColor(.brandTextDim)
            }
            if let tendency = data?.tendency {
                Text(tendency)
                    .scaledFont(size: 10, design: .monospaced)
                    .foregroundColor(.brandTextMuted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.brandSurface2)
        .cornerRadius(8)
    }

    // MARK: - Shared helpers
    private func statGrid(_ items: [(String, String)]) -> some View {
        HStack(spacing: 8) {
            ForEach(items, id: \.0) { label, value in
                VStack(spacing: 3) {
                    Text(value)
                        .scaledFont(size: 15, weight: .bold, design: .monospaced)
                        .foregroundColor(.brandText)
                    Text(label)
                        .scaledFont(size: 9, design: .monospaced)
                        .foregroundColor(.brandTextDim)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.brandSurface2)
                .cornerRadius(7)
            }
        }
    }

    private func splitBlock(label: String, avg: String?, k9: String?) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .scaledFont(size: 9, weight: .bold, design: .monospaced)
                .foregroundColor(.brandTextDim)
            if let avg { Text("\(avg) AVG").scaledFont(size: 11, design: .monospaced).foregroundColor(.brandTextMuted) }
            if let k9  { Text("\(k9) K/9").scaledFont(size: 11, design: .monospaced).foregroundColor(.brandCyan) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color.brandSurface2)
        .cornerRadius(7)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .scaledFont(size: 10, weight: .bold, design: .monospaced)
            .foregroundColor(.brandTextDim)
            .kerning(1.2)
    }

    private func noDataCard(_ msg: String) -> some View {
        Text(msg)
            .scaledFont(size: 12, design: .monospaced)
            .foregroundColor(.brandTextDim)
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(Color.brandSurface)
            .cornerRadius(10)
    }
}
