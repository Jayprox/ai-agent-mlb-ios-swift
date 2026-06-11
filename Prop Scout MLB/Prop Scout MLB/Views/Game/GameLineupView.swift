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
                        .font(.system(size: 12, design: .monospaced))
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
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
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
                            isInjured: vm.injuredIds.contains(batter.id)
                        )
                        .padding(.horizontal, 16)
                    }
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
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
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
    var isInjured: Bool = false

    @State private var isExpanded = false
    @State private var h2h: H2HStats? = nil
    @State private var stats: BatterHittingStats? = nil
    @State private var splits: BatterSplits? = nil
    @State private var statSplits: BatterSplits? = nil
    @State private var gamelog: BatterGamelog? = nil
    @State private var rbiContext: RBIContext? = nil
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
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.brandTextDim)
                        .frame(width: 16)

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(batter.name ?? "—")
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                .foregroundColor(.brandText)
                            if isInjured {
                                ILBadge()
                            }
                        }
                        HStack(spacing: 4) {
                            if let pos = batter.position {
                                Text(pos)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.brandTextDim)
                            }
                            if let side = batter.batSide {
                                Text("·")
                                    .foregroundColor(.brandTextDim)
                                Text("\(side)H")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.brandTextDim)
                            }
                        }
                    }

                    Spacer()

                    if let avg = batter.avg {
                        Text(avg)
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundColor(.brandTextMuted)
                    }

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10))
                        .foregroundColor(.brandTextDim)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
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
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
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
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.brandTextDim)
                        }
                    } else if pitcherId != nil && !loadedOnce {
                        Text("Loading…")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.brandTextDim)
                    }

                    // L/R splits (Statcast preferred, fall back to season splits)
                    let lr = statSplits ?? splits
                    if let vsL = lr?.vsLeft, let vsR = lr?.vsRight {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("VS L / VS R")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
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
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
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
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(.brandTextDim)
                                .kerning(1.2)
                            VStack(spacing: 4) {
                                ForEach(games.prefix(5)) { g in
                                    HStack {
                                        Text(g.opponent ?? g.date ?? "—")
                                            .font(.system(size: 10, design: .monospaced))
                                            .foregroundColor(.brandTextMuted)
                                        Spacer()
                                        if let ab = g.ab, let h = g.h {
                                            Text("\(h)-\(ab)")
                                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                                .foregroundColor(.brandText)
                                        }
                                        if let hr = g.hr, hr > 0 {
                                            Text("\(hr) HR")
                                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                                .foregroundColor(.brandAmber)
                                        }
                                        if let rbi = g.rbi, rbi > 0 {
                                            Text("\(rbi) RBI")
                                                .font(.system(size: 9, design: .monospaced))
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
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
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
            let (s, sp, ssp, gl, rbi, h) = await (statsTask, splitsTask, statSplitsTask, gamelogTask, rbiTask, h2hTask)
            DispatchQueue.main.async {
                self.stats = s
                self.splits = sp
                self.statSplits = ssp
                self.gamelog = gl
                self.rbiContext = rbi
                self.h2h   = h
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
                .font(.system(size: 8, design: .monospaced))
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
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(.brandText)
            Text(label)
                .font(.system(size: 7, design: .monospaced))
                .foregroundColor(.brandTextDim)
        }
    }

    private func statChip(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.brandText)
            Text(label)
                .font(.system(size: 8, design: .monospaced))
                .foregroundColor(.brandTextDim)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.brandSurface2)
        .cornerRadius(6)
    }
}
