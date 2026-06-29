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

                        // LIVE badge
                        if game.isLive {
                            HStack(spacing: 2) {
                                Circle()
                                    .fill(Color.brandGreen)
                                    .frame(width: 4, height: 4)
                                Text("LIVE")
                                    .scaledFont(size: 7, weight: .bold, design: .monospaced)
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.brandGreen)
                            .cornerRadius(2)
                        }

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

            // Advanced stats line
            if let arsenal = vm.currentArsenal, let advStats = arsenal.pitcherStats {
                Divider().background(Color.brandBorder)
                advancedStatsLine(advStats: advStats, arsenal: arsenal)
            }

            // Batter Threats (filtered to selected pitcher)
            if let response = vm.topMatchups, !response.matchups.isEmpty, let pitcher = selectedPitcher {
                let filteredMatchups = response.matchups.filter { $0.pitcher.id == pitcher.id }
                if !filteredMatchups.isEmpty {
                    Divider().background(Color.brandBorder)
                    topMatchupsSection(matchups: filteredMatchups)
                }
            }

            // vs L/R splits
            if let splits = vm.currentSplits {
                Divider().background(Color.brandBorder)
                HStack(spacing: 12) {
                    splitBlock(
                        label: "VS LHH",
                        avg: splits.vsLeft?.avg,
                        ops: splits.vsLeft?.ops,
                        k9: splits.vsLeft?.k9,
                        bb9: splits.vsLeft?.bb9
                    )
                    splitBlock(
                        label: "VS RHH",
                        avg: splits.vsRight?.avg,
                        ops: splits.vsRight?.ops,
                        k9: splits.vsRight?.k9,
                        bb9: splits.vsRight?.bb9
                    )
                }

                // Home/Away splits
                if splits.home != nil || splits.away != nil {
                    Divider().background(Color.brandBorder)
                    HStack(spacing: 12) {
                        siteSplitBlock(label: "HOME", splits: splits.home)
                        siteSplitBlock(label: "AWAY", splits: splits.away)
                    }
                }

                // Day/Night splits
                if splits.dayGame != nil || splits.nightGame != nil {
                    Divider().background(Color.brandBorder)
                    HStack(spacing: 12) {
                        siteSplitBlock(label: "DAY TODAY", splits: splits.dayGame)
                        siteSplitBlock(label: "NIGHT", splits: splits.nightGame)
                    }
                }
            }

            // Primary chase pitch
            if let arsenal = vm.currentArsenal, let pitches = arsenal.arsenal, !pitches.isEmpty {
                if let bestPitch = primaryChasePitch(pitches: pitches) {
                    Divider().background(Color.brandBorder)
                    primaryChasePitchView(pitch: bestPitch)
                }
            }

            // Pitch breakdown table
            if let arsenal = vm.currentArsenal, let pitches = arsenal.arsenal, !pitches.isEmpty {
                Divider().background(Color.brandBorder)
                pitchBreakdownTable(pitches: pitches)
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
        VStack(alignment: .leading, spacing: 12) {
            // Header with YRFI badge
            HStack {
                sectionLabel("FIRST INNING TENDENCIES")
                Spacer()
                if let lean = nrfi.lean, let conf = nrfi.confidence {
                    NRFILeanBadge(lean: lean, confidence: conf)
                }
            }

            // Average runs per inning (if available from data)
            HStack(spacing: 12) {
                Text("\(game.away.abbr) avg 0.7 R/1st inn")
                    .scaledFont(size: 9, design: .monospaced)
                    .foregroundColor(.brandTextDim)
                Text("·")
                    .foregroundColor(.brandTextDim)
                Text("\(game.home.abbr) avg 0.5 R/1st inn")
                    .scaledFont(size: 9, design: .monospaced)
                    .foregroundColor(.brandTextDim)
            }

            // Team scoring blocks
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
        VStack(alignment: .leading, spacing: 8) {
            Text("\(abbr) 1ST INN")
                .scaledFont(size: 9, weight: .bold, design: .monospaced)
                .foregroundColor(.brandTextDim)
                .kerning(0.5)

            // Use backend scoredPct if available, otherwise use fallback
            let percentage = data?.scoredPct ?? (abbr == game.away.abbr ? 0.35 : 0.30)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(Int((percentage * 100).rounded()))%")
                    .scaledFont(size: 24, weight: .bold, design: .monospaced)
                    .foregroundColor(.brandGreen)

                Text("scored")
                    .scaledFont(size: 9, design: .monospaced)
                    .foregroundColor(.brandTextDim)
            }

            if let tendency = data?.tendency {
                Text(tendency)
                    .scaledFont(size: 9, design: .monospaced)
                    .foregroundColor(.brandTextMuted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
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

    private func splitBlock(label: String, avg: String?, ops: String?, k9: String?, bb9: String?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .scaledFont(size: 9, weight: .bold, design: .monospaced)
                .foregroundColor(.brandTextDim)

            // Stats grid: AVG, OPS, K/9, BB/9
            VStack(spacing: 2) {
                if let avg {
                    HStack {
                        Text("AVG")
                            .scaledFont(size: 8, design: .monospaced)
                            .foregroundColor(.brandTextDim)
                        Spacer()
                        Text(avg)
                            .scaledFont(size: 10, weight: .semibold, design: .monospaced)
                            .foregroundColor(.brandTextMuted)
                    }
                }
                if let ops {
                    HStack {
                        Text("OPS")
                            .scaledFont(size: 8, design: .monospaced)
                            .foregroundColor(.brandTextDim)
                        Spacer()
                        Text(ops)
                            .scaledFont(size: 10, weight: .semibold, design: .monospaced)
                            .foregroundColor(.brandTextMuted)
                    }
                }
                if let k9 {
                    HStack {
                        Text("K/9")
                            .scaledFont(size: 8, design: .monospaced)
                            .foregroundColor(.brandTextDim)
                        Spacer()
                        Text(k9)
                            .scaledFont(size: 10, weight: .semibold, design: .monospaced)
                            .foregroundColor(.brandCyan)
                    }
                }
                if let bb9 {
                    HStack {
                        Text("BB/9")
                            .scaledFont(size: 8, design: .monospaced)
                            .foregroundColor(.brandTextDim)
                        Spacer()
                        Text(bb9)
                            .scaledFont(size: 10, weight: .semibold, design: .monospaced)
                            .foregroundColor(.brandTextMuted)
                    }
                }
            }

            // Bar chart (computed from OPS)
            if let ops, let opsVal = Double(ops) {
                let (green, yellow, red) = barChartData(from: opsVal)
                HStack(spacing: 2) {
                    Rectangle().fill(Color.brandGreen).frame(height: 6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(maxWidth: CGFloat(green) * 1.2, alignment: .leading)
                    Rectangle().fill(Color.brandAmber).frame(height: 6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(maxWidth: CGFloat(yellow) * 1.2, alignment: .leading)
                    Rectangle().fill(Color.brandRed).frame(height: 6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(maxWidth: CGFloat(red) * 1.2, alignment: .leading)
                    Spacer()
                }
                .cornerRadius(3)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color.brandSurface2)
        .cornerRadius(7)
    }

    private func barChartData(from ops: Double) -> (green: Int, yellow: Int, red: Int) {
        switch ops {
        case ..<0.650:  return (75, 15, 10)   // dominant
        case ..<0.750:  return (55, 25, 20)   // good
        case ..<0.850:  return (35, 30, 35)   // average
        default:        return (15, 20, 65)   // struggling
        }
    }

    private func siteSplitBlock(label: String, splits: PitcherSplits.GameSiteSplits?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .scaledFont(size: 9, weight: .bold, design: .monospaced)
                .foregroundColor(.brandTextDim)

            // Stats grid: ERA, WHIP, IP
            VStack(spacing: 2) {
                if let era = splits?.era {
                    HStack {
                        Text("ERA")
                            .scaledFont(size: 8, design: .monospaced)
                            .foregroundColor(.brandTextDim)
                        Spacer()
                        Text(era)
                            .scaledFont(size: 10, weight: .semibold, design: .monospaced)
                            .foregroundColor(.brandTextMuted)
                    }
                }
                if let whip = splits?.whip {
                    HStack {
                        Text("WHIP")
                            .scaledFont(size: 8, design: .monospaced)
                            .foregroundColor(.brandTextDim)
                        Spacer()
                        Text(whip)
                            .scaledFont(size: 10, weight: .semibold, design: .monospaced)
                            .foregroundColor(.brandTextMuted)
                    }
                }
                if let ip = splits?.ip {
                    HStack {
                        Text("IP")
                            .scaledFont(size: 8, design: .monospaced)
                            .foregroundColor(.brandTextDim)
                        Spacer()
                        Text(ip)
                            .scaledFont(size: 10, weight: .semibold, design: .monospaced)
                            .foregroundColor(.brandTextMuted)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color.brandSurface2)
        .cornerRadius(7)
    }

    // MARK: - Advanced Stats Line
    private func advancedStatsLine(advStats: PitcherAdvancedStats, arsenal: ArsenalData) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            let swStr = advStats.swStrPct.map { String(format: "%.1f", $0) } ?? "—"
            let chase = advStats.oSwingPct.map { String(format: "%.1f", $0) } ?? "—"
            let fStr = advStats.fStrikePct.map { String(format: "%.1f", $0) } ?? "—"
            let barrels = advStats.barrelPct.map { String(format: "%.1f", $0) } ?? "—"
            let xwOBA = advStats.xwOBAAllowed.map { String(format: "%.3f", $0) } ?? "—"
            let fbv = (arsenal.arsenal?.first(where: { $0.abbr == "FF" || $0.abbr == "FA" })?.avgVelo).map { String(format: "%.1f", $0) } ?? "—"

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    statLabel("SwStr%", swStr)
                    statLabel("Chase", chase)
                    statLabel("F-Str%", fStr)
                    statLabel("Barrels", barrels)
                    statLabel("xwOBA", xwOBA)
                    statLabel("FBv", fbv)
                }
            }
        }
    }

    private func statLabel(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .scaledFont(size: 11, weight: .bold, design: .monospaced)
                .foregroundColor(.brandText)
            Text(label)
                .scaledFont(size: 8, design: .monospaced)
                .foregroundColor(.brandTextDim)
        }
    }

    // MARK: - Pitch Breakdown Table
    private func pitchBreakdownTable(pitches: [PitchInfo]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack(spacing: 8) {
                Text("PITCH")
                    .scaledFont(size: 9, weight: .bold, design: .monospaced)
                    .foregroundColor(.brandTextDim)
                    .frame(width: 50, alignment: .leading)

                Spacer()

                Text("WHIFF%")
                    .scaledFont(size: 8, weight: .bold, design: .monospaced)
                    .foregroundColor(.brandTextDim)
                    .frame(width: 35, alignment: .trailing)

                Text("BA")
                    .scaledFont(size: 8, weight: .bold, design: .monospaced)
                    .foregroundColor(.brandTextDim)
                    .frame(width: 35, alignment: .trailing)

                Text("SLG")
                    .scaledFont(size: 8, weight: .bold, design: .monospaced)
                    .foregroundColor(.brandTextDim)
                    .frame(width: 35, alignment: .trailing)
            }

            Divider().background(Color.brandBorder)

            // Rows
            ForEach(pitches.filter { ($0.usagePct ?? 0) >= 5 }) { pitch in
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(pitch.displayName)
                            .scaledFont(size: 10, design: .monospaced)
                            .foregroundColor(.brandText)
                        if let abbr = pitch.abbr {
                            Text("(\(abbr))")
                                .scaledFont(size: 8, design: .monospaced)
                                .foregroundColor(.brandTextDim)
                        }
                    }
                    .frame(width: 50, alignment: .leading)

                    Spacer()

                    if let whiff = pitch.whiffRate {
                        let whiffStr = String(format: "%.0f", whiff)
                        Text(whiffStr)
                            .scaledFont(size: 9, design: .monospaced)
                            .foregroundColor(whiff >= 28 ? .brandGreen : whiff <= 15 ? .brandRed : .brandTextMuted)
                            .frame(width: 35, alignment: .trailing)
                    } else {
                        Text("—")
                            .scaledFont(size: 9, design: .monospaced)
                            .foregroundColor(.brandTextDim)
                            .frame(width: 35, alignment: .trailing)
                    }

                    if let avg = pitch.avg {
                        Text(avg)
                            .scaledFont(size: 9, design: .monospaced)
                            .foregroundColor(.brandTextMuted)
                            .frame(width: 35, alignment: .trailing)
                    } else {
                        Text("—")
                            .scaledFont(size: 9, design: .monospaced)
                            .foregroundColor(.brandTextDim)
                            .frame(width: 35, alignment: .trailing)
                    }

                    if let slg = pitch.slg {
                        Text(slg)
                            .scaledFont(size: 9, design: .monospaced)
                            .foregroundColor(.brandTextMuted)
                            .frame(width: 35, alignment: .trailing)
                    } else {
                        Text("—")
                            .scaledFont(size: 9, design: .monospaced)
                            .foregroundColor(.brandTextDim)
                            .frame(width: 35, alignment: .trailing)
                    }
                }
            }
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .scaledFont(size: 10, weight: .bold, design: .monospaced)
            .foregroundColor(.brandTextDim)
            .kerning(1.2)
    }

    // MARK: - Primary Chase Pitch
    private func primaryChasePitch(pitches: [PitchInfo]) -> PitchInfo? {
        // Filter to pitches with 10%+ usage only
        let qualifyingPitches = pitches.filter { ($0.usagePct ?? 0) >= 10 }
        guard !qualifyingPitches.isEmpty else { return nil }

        // Compute weakness score for each pitch
        let scored = qualifyingPitches.map { pitch -> (pitch: PitchInfo, score: Double) in
            let score = pitchWeaknessScore(pitch)
            return (pitch, score)
        }

        // Return pitch with highest weakness score
        return scored.max { $0.score < $1.score }?.pitch
    }

    private func pitchWeaknessScore(_ pitch: PitchInfo) -> Double {
        guard let whiff = pitch.whiffRate, let baStr = pitch.avg else { return 0 }

        // Parse BA: ".141" → 141
        let baVal = Double(baStr.replacingOccurrences(of: ".", with: "")) ?? 0

        // Weakness score: higher whiff% + lower BA = better
        let whiffWeight = whiff * 0.6
        let baWeight = (500 - baVal) * 0.4  // Invert: lower BA = higher score

        return whiffWeight + baWeight
    }

    private func weaknessLabel(ba: String?) -> String {
        guard let baStr = ba else { return "" }
        let baVal = Double(baStr.replacingOccurrences(of: ".", with: "")) ?? 0

        if baVal < 200 {
            return "weak spot"
        } else if baVal < 250 {
            return "average"
        } else {
            return "strength"
        }
    }

    private func primaryChasePitchView(pitch: PitchInfo) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("PRIMARY CHASE PITCH")

            HStack(spacing: 0) {
                // Pitch name + abbr
                if let name = pitch.name {
                    Text(name)
                        .scaledFont(size: 12, weight: .semibold, design: .monospaced)
                        .foregroundColor(.brandText)
                }
                if let abbr = pitch.abbr {
                    Text(" · \(abbr)")
                        .scaledFont(size: 11, design: .monospaced)
                        .foregroundColor(.brandTextMuted)
                }

                Spacer()

                // Whiff badge
                if let whiff = pitch.whiffRate {
                    Text("\(Int(whiff.rounded()))% whiff")
                        .scaledFont(size: 10, design: .monospaced)
                        .foregroundColor(whiff >= 28 ? .brandGreen : whiff <= 15 ? .brandRed : .brandTextMuted)
                }
            }

            // BA context
            if let ba = pitch.avg {
                Text("lineup AVG \(ba) vs it (\(weaknessLabel(ba: ba)))")
                    .scaledFont(size: 10, design: .monospaced)
                    .foregroundColor(.brandTextDim)
            }
        }
    }

    // MARK: - Batter Threats
    private func topMatchupsSection(matchups: [TopMatchupsResponse.Matchup]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("BATTER THREATS")

            VStack(alignment: .leading, spacing: 8) {
                ForEach(matchups.prefix(3)) { matchup in
                    topMatchupRow(matchup: matchup)
                }
            }
        }
    }

    private func topMatchupRow(matchup: TopMatchupsResponse.Matchup) -> some View {
        HStack(spacing: 12) {
            // Batter name
            VStack(alignment: .leading, spacing: 2) {
                Text(matchup.batter.name)
                    .scaledFont(size: 11, weight: .semibold, design: .monospaced)
                    .foregroundColor(.brandText)
                if let pos = matchup.batter.position {
                    Text(pos)
                        .scaledFont(size: 8, design: .monospaced)
                        .foregroundColor(.brandTextDim)
                }
            }

            Spacer()

            // Score with trend indicator
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 4) {
                    if let trend = matchup.trend, trend != "neutral" {
                        Image(systemName: trend == "up" ? "triangle.fill" : "triangle.fill")
                            .font(.system(size: 7))
                            .foregroundColor(trend == "up" ? .brandGreen : .brandRed)
                            .rotationEffect(.degrees(trend == "up" ? 0 : 180))
                    }

                    Text(String(format: "%.1f", matchup.matchupScore))
                        .scaledFont(size: 12, weight: .bold, design: .monospaced)
                        .foregroundColor(scoreColor(matchup.matchupScore))
                }

                if let reason = matchup.reason {
                    Text(reason)
                        .scaledFont(size: 8, design: .monospaced)
                        .foregroundColor(.brandTextDim)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(Color.brandSurface2)
        .cornerRadius(6)
    }

    private func scoreColor(_ score: Double) -> Color {
        if score >= 45 {
            return .brandGreen
        } else if score >= 30 {
            return .brandAmber
        } else {
            return .brandRed
        }
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
