import SwiftUI

struct GameLineupView: View {
    let game: SlateGame
    @ObservedObject var vm: GameDetailViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                sideToggle
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                if vm.currentLineup.isEmpty {
                    Text(vm.lineup == nil ? "Loading lineups…" : "Lineup not yet confirmed")
                        .scaledFont(size: 12, design: .monospaced)
                        .foregroundColor(.brandTextDim)
                        .frame(maxWidth: .infinity)
                        .padding(24)
                        .background(Color.brandSurface)
                        .cornerRadius(10)
                        .padding(.horizontal, 16)
                } else {
                    let pitcher = vm.lineupSide == .away
                        ? game.probablePitchers?.home
                        : game.probablePitchers?.away

                    HStack {
                        Text("VS \(pitcher?.name.components(separatedBy: " ").last?.uppercased() ?? "SP")")
                            .scaledFont(size: 10, weight: .bold, design: .monospaced)
                            .foregroundColor(.brandTextDim)
                            .kerning(1.2)
                        Spacer()
                    }
                    .padding(.horizontal, 16)

                    ForEach(Array(vm.currentLineup.enumerated()), id: \.element.id) { idx, batter in
                        ExpandableBatterRowView(
                            order: idx + 1,
                            batter: batter,
                            pitcherId: pitcher?.id,
                            topMatchups: vm.topMatchups,
                            isInjured: vm.injuredIds.contains(batter.id),
                            isLive: game.isLive
                        )
                        .padding(.horizontal, 16)
                    }

                    // Matchup score legend
                    VStack(alignment: .leading, spacing: 10) {
                        Divider().background(Color.brandBorder)

                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Circle().fill(Color(red: 0.35, green: 0.85, blue: 0.35)).frame(width: 6, height: 6)
                                    Text("< 35").scaledFont(size: 9, design: .monospaced).foregroundColor(.brandTextDim)
                                }
                                Text("Pitcher Edge").scaledFont(size: 8, design: .monospaced).foregroundColor(.brandTextMuted)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Circle().fill(Color(red: 1.0, green: 0.75, blue: 0.3)).frame(width: 6, height: 6)
                                    Text("35-54").scaledFont(size: 9, design: .monospaced).foregroundColor(.brandTextDim)
                                }
                                Text("Neutral").scaledFont(size: 8, design: .monospaced).foregroundColor(.brandTextMuted)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Circle().fill(Color(red: 0.9, green: 0.35, blue: 0.35)).frame(width: 6, height: 6)
                                    Text("55+").scaledFont(size: 9, design: .monospaced).foregroundColor(.brandTextDim)
                                }
                                Text("Batter Edge").scaledFont(size: 8, design: .monospaced).foregroundColor(.brandTextMuted)
                            }

                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                    }
                    .padding(.horizontal, 16)
                }

                Spacer(minLength: 20)
            }
        }
        .background(Color.brandBackground)
    }

    private var sideToggle: some View {
        HStack(spacing: 0) {
            sideButton("\(game.away.abbr) BATTING", side: .away)
            sideButton("\(game.home.abbr) BATTING", side: .home)
        }
        .background(Color.brandSurface2)
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.brandBorder, lineWidth: 1))
    }

    private func sideButton(_ label: String, side: GameDetailViewModel.SPSide) -> some View {
        Button { vm.lineupSide = side } label: {
            Text(label)
                .scaledFont(size: 11, weight: .semibold, design: .monospaced)
                .foregroundColor(vm.lineupSide == side ? .brandBackground : .brandTextMuted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(vm.lineupSide == side ? Color.brandGreen : Color.clear)
                .cornerRadius(7)
        }
    }
}

// MARK: - Expandable batter row
struct ExpandableBatterRowView: View {
    let order: Int
    let batter: LineupBatter
    let pitcherId: Int?
    let topMatchups: TopMatchupsResponse?
    var isInjured: Bool = false
    var isLive: Bool = false

    @State private var isExpanded = false
    @State private var h2h: H2HStats? = nil
    @State private var stats: BatterHittingStats? = nil
    @State private var splits: BatterSplits? = nil
    @State private var statSplits: BatterSplits? = nil
    @State private var gamelog: BatterGamelog? = nil
    @State private var rbiContext: RBIContext? = nil
    @State private var arsenalVsBatter: ArsenalVsBatterResponse? = nil
    @State private var loadedOnce = false

    var body: some View {
        VStack(spacing: 0) {
            // MARK: Collapsed row
            Button {
                HapticManager.light()
                withAnimation(.easeInOut(duration: 0.22)) {
                    isExpanded.toggle()
                }
                if !loadedOnce { Task { await fetchDetails() } }
            } label: {
                HStack(spacing: 12) {
                    Text("\(order)")
                        .scaledFont(size: 12, weight: .bold, design: .monospaced)
                        .foregroundColor(.brandTextDim)
                        .frame(width: 16)

                    VStack(alignment: .leading, spacing: 3) {
                        // Name with LIVE, HOT/COLD and IL badges
                        HStack(spacing: 6) {
                            Text(batter.name ?? "—")
                                .scaledFont(size: 12, weight: .semibold, design: .monospaced)
                                .foregroundColor(.brandText)

                            // LIVE badge
                            if isLive {
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

                            // HOT/COLD badge
                            if let hot = batter.recentForm?.hotStreak, hot {
                                Text("HOT")
                                    .scaledFont(size: 7, weight: .bold, design: .monospaced)
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(Color(red: 0.35, green: 0.85, blue: 0.35))
                                    .cornerRadius(2)
                            } else if let cold = batter.recentForm?.coldStreak, cold {
                                Text("COLD")
                                    .scaledFont(size: 7, weight: .bold, design: .monospaced)
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(Color(red: 0.9, green: 0.35, blue: 0.35))
                                    .cornerRadius(2)
                            }

                            if isInjured {
                                ILBadge()
                            }
                        }

                        // Stats line: POS LH AVG
                        HStack(spacing: 6) {
                            if let pos = batter.position {
                                Text(pos)
                                    .scaledFont(size: 8, design: .monospaced)
                                    .foregroundColor(.brandTextDim)
                            }
                            if let side = batter.batSide {
                                Text("\(side)H")
                                    .scaledFont(size: 8, design: .monospaced)
                                    .foregroundColor(.brandTextDim)
                            }
                            // Always show avg (fallback to dash)
                            Text(batter.avg ?? "—")
                                .scaledFont(size: 8, design: .monospaced)
                                .foregroundColor(.brandTextMuted)
                        }

                        // Indicator dots
                        HStack(spacing: 3) {
                            ForEach(0..<4, id: \.self) { _ in
                                Circle()
                                    .fill(Color.brandCyan)
                                    .frame(width: 3, height: 3)
                            }
                        }
                    }

                    Spacer()

                    // Matchup score (colored box)
                    if let score = matchupScore(for: batter) {
                        Text(String(format: "%.1f", score))
                            .scaledFont(size: 12, weight: .bold, design: .monospaced)
                            .foregroundColor(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(matchupScoreBackgroundColor(score))
                            .cornerRadius(4)
                    }

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .scaledFont(size: 10)
                        .foregroundColor(.brandTextDim)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // MARK: Expanded drawer
            if isExpanded {
                Divider().background(Color.brandBorder).padding(.horizontal, 14)

                VStack(alignment: .leading, spacing: 10) {
                    // Season stats
                    if let s = stats {
                        HStack(spacing: 8) {
                            if let avg = s.avg  { statChip("AVG",  avg) }
                            if let ops = s.ops  { statChip("OPS",  ops) }
                            if let hr = s.hr    { statChip("HR",   "\(hr)") }
                            if let rbi = s.rbi  { statChip("RBI",  "\(rbi)") }
                        }
                    }

                    // Career H2H vs pitcher
                    if let h = h2h {
                        if h.atBats > 0 {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("CAREER VS PITCHER")
                                    .scaledFont(size: 9, weight: .bold, design: .monospaced)
                                    .foregroundColor(.brandTextDim)
                                    .kerning(1.2)
                                HStack(spacing: 8) {
                                    statChip("AVG",  h.avg ?? "—")
                                    statChip("AB",   "\(h.atBats)")
                                    if let hr = h.homeRuns { statChip("HR", "\(hr)") }
                                    if let k  = h.strikeOuts { statChip("K", "\(k)") }
                                }
                            }
                        } else {
                            Text("No career history vs this pitcher")
                                .scaledFont(size: 10, design: .monospaced)
                                .foregroundColor(.brandTextDim)
                        }
                    } else if pitcherId != nil && !loadedOnce {
                        Text("Loading…")
                            .scaledFont(size: 10, design: .monospaced)
                            .foregroundColor(.brandTextDim)
                    }

                    // L/R splits (Statcast preferred, fall back to season splits)
                    let lr = statSplits ?? splits
                    if let vsL = lr?.vsLeft, let vsR = lr?.vsRight {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("VS L / VS R")
                                .scaledFont(size: 9, weight: .bold, design: .monospaced)
                                .foregroundColor(.brandTextDim)
                                .kerning(1.2)
                            HStack(spacing: 8) {
                                splitColumn(label: "VS LHP", line: vsL)
                                splitColumn(label: "VS RHP", line: vsR)
                            }
                        }
                    }

                    // Home/Away splits
                    if let home = splits?.home, let away = splits?.away {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("HOME / AWAY")
                                .scaledFont(size: 9, weight: .bold, design: .monospaced)
                                .foregroundColor(.brandTextDim)
                                .kerning(1.2)
                            HStack(spacing: 8) {
                                splitColumn(label: "HOME", line: home)
                                splitColumn(label: "AWAY", line: away)
                            }
                        }
                    }

                    // Last 5 games
                    if let games = gamelog?.games, !games.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("LAST 5 GAMES")
                                .scaledFont(size: 9, weight: .bold, design: .monospaced)
                                .foregroundColor(.brandTextDim)
                                .kerning(1.2)
                            VStack(spacing: 4) {
                                ForEach(games.prefix(5)) { g in
                                    HStack {
                                        Text(g.opponent ?? g.date ?? "—")
                                            .scaledFont(size: 10, design: .monospaced)
                                            .foregroundColor(.brandTextMuted)
                                        Spacer()
                                        if let ab = g.ab, let h = g.h {
                                            Text("\(h)-\(ab)")
                                                .scaledFont(size: 10, weight: .semibold, design: .monospaced)
                                                .foregroundColor(.brandText)
                                        }
                                        if let hr = g.hr, hr > 0 {
                                            Text("\(hr) HR")
                                                .scaledFont(size: 9, weight: .bold, design: .monospaced)
                                                .foregroundColor(.brandAmber)
                                        }
                                        if let rbi = g.rbi, rbi > 0 {
                                            Text("\(rbi) RBI")
                                                .scaledFont(size: 9, design: .monospaced)
                                                .foregroundColor(.brandTextDim)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // RBI opportunity context
                    if let rbiCtx = rbiContext {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("RBI CONTEXT")
                                .scaledFont(size: 9, weight: .bold, design: .monospaced)
                                .foregroundColor(.brandTextDim)
                                .kerning(1.2)
                            HStack(spacing: 8) {
                                if let risp = rbiCtx.avgRISP { statChip("AVG W/ RISP", risp) }
                                if let opp = rbiCtx.rispOpportunities { statChip("RISP OPP", "\(opp)") }
                                if let rate = rbiCtx.runnersOnRate { statChip("ON BASE%", "\(Int(rate * 100))%") }
                                if let clutch = rbiCtx.clutchRating { statChip("CLUTCH", clutch) }
                            }
                        }
                    }

                    // Arsenal vs batter (pitch-by-pitch analysis)
                    if let arsenal = arsenalVsBatter {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("PITCH ANALYSIS")
                                .scaledFont(size: 9, weight: .bold, design: .monospaced)
                                .foregroundColor(.brandTextDim)
                                .kerning(1.2)

                            VStack(spacing: 12) {
                                ForEach(arsenal.arsenal) { pitch in
                                    pitchCard(pitch: pitch)
                                }
                            }
                        }
                    } else if pitcherId != nil && !loadedOnce {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("PITCH ANALYSIS")
                                .scaledFont(size: 9, weight: .bold, design: .monospaced)
                                .foregroundColor(.brandTextDim)
                                .kerning(1.2)
                            Text("Loading…")
                                .scaledFont(size: 10, design: .monospaced)
                                .foregroundColor(.brandTextDim)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 12)
                .padding(.top, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color.brandSurface)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.brandBorder, lineWidth: 1))
        .clipped()
    }

    // MARK: - Fetch
    private func fetchDetails() async {
        loadedOnce = true
        let batterId = batter.id
        guard batterId > 0 else { return }

        async let statsTask: BatterHittingStats? = try? APIClient.shared.get(
            path: "/api/players/\(batterId)/stats?group=hitting"
        )
        async let splitsTask: BatterSplits? = try? APIClient.shared.get(
            path: "/api/splits/\(batterId)"
        )
        async let statSplitsTask: BatterSplits? = try? APIClient.shared.get(
            path: "/api/stat-splits/\(batterId)?group=hitting"
        )
        async let gamelogTask: BatterGamelog? = try? APIClient.shared.get(
            path: "/api/players/\(batterId)/gamelog?group=hitting"
        )
        async let rbiTask: RBIContext? = try? APIClient.shared.get(
            path: "/api/players/\(batterId)/rbi-context"
        )

        if let pitcherId {
            async let h2hTask: H2HStats? = try? APIClient.shared.get(
                path: "/api/players/\(batterId)/vs/\(pitcherId)"
            )
            async let arsenalTask: ArsenalVsBatterResponse? = try? APIClient.shared.get(
                path: "/api/arsenal/\(pitcherId)/vs/\(batterId)"
            )
            let (s, sp, ssp, gl, rbi, h, ars) = await (statsTask, splitsTask, statSplitsTask, gamelogTask, rbiTask, h2hTask, arsenalTask)
            DispatchQueue.main.async {
                self.stats = s
                self.splits = sp
                self.statSplits = ssp
                self.gamelog = gl
                self.rbiContext = rbi
                self.h2h = h
                self.arsenalVsBatter = ars
            }
        } else {
            let (s, sp, ssp, gl, rbi) = await (statsTask, splitsTask, statSplitsTask, gamelogTask, rbiTask)
            DispatchQueue.main.async {
                self.stats = s
                self.splits = sp
                self.statSplits = ssp
                self.gamelog = gl
                self.rbiContext = rbi
            }
        }
    }

    // MARK: - Split column
    private func splitColumn(label: String, line: StatSplitLine) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .scaledFont(size: 8, design: .monospaced)
                .foregroundColor(.brandTextDim)
            HStack(spacing: 6) {
                if let avg = line.avg { miniStat("AVG", avg) }
                if let ops = line.ops { miniStat("OPS", ops) }
                if let hr = line.hr { miniStat("HR", "\(hr)") }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color.brandSurface2)
        .cornerRadius(6)
    }

    private func miniStat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 1) {
            Text(value)
                .scaledFont(size: 11, weight: .semibold, design: .monospaced)
                .foregroundColor(.brandText)
            Text(label)
                .scaledFont(size: 7, design: .monospaced)
                .foregroundColor(.brandTextDim)
        }
    }

    private func statChip(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .scaledFont(size: 12, weight: .bold, design: .monospaced)
                .foregroundColor(.brandText)
            Text(label)
                .scaledFont(size: 8, design: .monospaced)
                .foregroundColor(.brandTextDim)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.brandSurface2)
        .cornerRadius(6)
    }

    // MARK: - Pitch card
    private func pitchCard(pitch: ArsenalVsBatterResponse.PitchCard) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header: pitch name, label badge, velo
            HStack(spacing: 8) {
                HStack(spacing: 6) {
                    Text(pitch.abbr)
                        .scaledFont(size: 9, weight: .bold, design: .monospaced)
                        .foregroundColor(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(pitch.pitchColorValue)
                        .cornerRadius(3)

                    Text(pitch.type)
                        .scaledFont(size: 11, weight: .semibold, design: .monospaced)
                        .foregroundColor(.brandText)
                }

                Spacer()

                // Label badge
                Text(pitch.label)
                    .scaledFont(size: 8, weight: .bold, design: .monospaced)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(pitch.labelBackgroundColor)
                    .cornerRadius(3)
            }

            // Pitch stats: velo, usage, whiff
            HStack(spacing: 12) {
                if let velo = pitch.velo {
                    HStack(spacing: 4) {
                        Text(velo)
                            .scaledFont(size: 10, weight: .semibold, design: .monospaced)
                            .foregroundColor(.brandText)
                        Text("mph")
                            .scaledFont(size: 8, design: .monospaced)
                            .foregroundColor(.brandTextDim)
                    }
                }

                Text("•")
                    .foregroundColor(.brandTextDim)

                Text("\(pitch.pct)% usage")
                    .scaledFont(size: 10, design: .monospaced)
                    .foregroundColor(.brandTextDim)

                if let whiff = pitch.whiffPct {
                    Text("•")
                        .foregroundColor(.brandTextDim)
                    Text("\(whiff)% whiff")
                        .scaledFont(size: 10, design: .monospaced)
                        .foregroundColor(.brandTextDim)
                }
            }

            // YoY velocity delta
            if let badge = pitch.velocityBadge {
                Text(badge)
                    .scaledFont(size: 9, weight: .semibold, design: .monospaced)
                    .foregroundColor(pitch.velocityBadgeColor)
            }

            Divider().background(Color.brandBorder)

            // Usage bar
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.brandSurface2)
                    .frame(height: 4)

                RoundedRectangle(cornerRadius: 2)
                    .fill(pitch.pitchColorValue)
                    .frame(width: CGFloat(pitch.pct) / 100 * 200, height: 4)
            }
            .frame(maxWidth: 200)

            // Batter vs pitch stats
            HStack(spacing: 12) {
                if let avg = pitch.batterAvg {
                    VStack(spacing: 2) {
                        Text(avg)
                            .scaledFont(size: 11, weight: .bold, design: .monospaced)
                            .foregroundColor(.brandText)
                        Text("AVG")
                            .scaledFont(size: 7, design: .monospaced)
                            .foregroundColor(.brandTextDim)
                    }
                }

                if let whiff = pitch.batterWhiff {
                    VStack(spacing: 2) {
                        Text(whiff)
                            .scaledFont(size: 11, weight: .bold, design: .monospaced)
                            .foregroundColor(.brandText)
                        Text("WHIFF")
                            .scaledFont(size: 7, design: .monospaced)
                            .foregroundColor(.brandTextDim)
                    }
                }

                if let slg = pitch.batterSlg {
                    VStack(spacing: 2) {
                        Text(slg)
                            .scaledFont(size: 11, weight: .bold, design: .monospaced)
                            .foregroundColor(.brandText)
                        Text("SLG")
                            .scaledFont(size: 7, design: .monospaced)
                            .foregroundColor(.brandTextDim)
                    }
                }

                Spacer()
            }

            // Note
            if let note = pitch.note {
                Text(note)
                    .scaledFont(size: 9, design: .monospaced)
                    .foregroundColor(.brandTextMuted)
                    .lineLimit(2)
            }

            // Risk note
            if let riskNote = pitch.riskNote {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .scaledFont(size: 10)
                    Text(riskNote)
                        .scaledFont(size: 9, design: .monospaced)
                        .lineLimit(2)
                }
                .foregroundColor(pitch.label == "WEAK SPOT" ? Color(red: 0.94, green: 0.26, blue: 0.26) : Color(red: 0.13, green: 0.78, blue: 0.35))
                .padding(8)
                .background(pitch.label == "WEAK SPOT" ?
                    Color(red: 0.94, green: 0.26, blue: 0.26, opacity: 0.1) :
                    Color(red: 0.13, green: 0.78, blue: 0.35, opacity: 0.1))
                .cornerRadius(4)
            }
        }
        .padding(10)
        .background(Color.brandSurface2)
        .cornerRadius(6)
    }

    // MARK: - Status Badge helpers
    private var statusBadgeText: String? {
        // Use batter's season average
        guard let avgStr = batter.avg, let avgVal = Double(avgStr) else { return nil }

        if avgVal > 0.300 {
            return "HOT"
        } else if avgVal < 0.200 {
            return "COLD"
        }

        return nil
    }

    private var statusBadgeColor: Color? {
        guard let text = statusBadgeText else { return nil }
        return text == "HOT" ? Color.brandGreen : text == "COLD" ? Color.brandRed : nil
    }

    // MARK: - Matchup Score helpers
    private func matchupScore(for batter: LineupBatter) -> Double? {
        return batter.matchupScore
    }

    private func matchupScoreBackgroundColor(_ score: Double) -> Color {
        if score >= 55 {
            return Color(red: 0.9, green: 0.35, blue: 0.35)  // Light red - Batter Edge
        } else if score >= 35 {
            return Color(red: 1.0, green: 0.75, blue: 0.3)   // Light amber - Neutral
        } else {
            return Color(red: 0.35, green: 0.85, blue: 0.35) // Light green - Pitcher Edge
        }
    }
}
