import SwiftUI

struct GameBoxscoreView: View {
    let game: SlateGame
    @ObservedObject var vm: GameDetailViewModel

    @State private var side: GameDetailViewModel.SPSide = .away

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                if let bx = vm.boxscore {
                    linescoreGrid(bx)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)

                    let battingPlayers = (side == .away ? bx.batting?.away : bx.batting?.home) ?? []
                    let pitchingPlayers = (side == .away ? bx.pitching?.away : bx.pitching?.home) ?? []
                    let sideAbbr = side == .away ? game.away.abbr : game.home.abbr

                    battingTable(battingPlayers)
                        .padding(.horizontal, 16)

                    pitchingTable(pitchingPlayers, teamAbbr: sideAbbr)
                        .padding(.horizontal, 16)
                } else if vm.isLoading {
                    Text("Loading boxscore…")
                        .scaledFont(size: 12, design: .monospaced)
                        .foregroundColor(.brandTextDim)
                        .frame(maxWidth: .infinity)
                        .padding(24)
                        .background(Color.brandSurface)
                        .cornerRadius(10)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                } else {
                    Text("Boxscore not yet available")
                        .scaledFont(size: 12, design: .monospaced)
                        .foregroundColor(.brandTextDim)
                        .frame(maxWidth: .infinity)
                        .padding(24)
                        .background(Color.brandSurface)
                        .cornerRadius(10)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                }

                Spacer(minLength: 20)
            }
        }
        .background(Color.brandBackground)
    }

    // MARK: - Side toggle (compact pills, used in Batting card header)
    private var sideToggle: some View {
        HStack(spacing: 4) {
            sideButton("\(game.away.abbr)", side: .away)
            sideButton("\(game.home.abbr)", side: .home)
        }
        .padding(3)
        .background(Color.brandSurface2)
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.brandBorder, lineWidth: 1))
    }

    private func sideButton(_ label: String, side: GameDetailViewModel.SPSide) -> some View {
        Button { self.side = side } label: {
            Text(label)
                .scaledFont(size: 10, weight: .bold, design: .monospaced)
                .foregroundColor(self.side == side ? .brandBackground : .brandTextMuted)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(self.side == side ? Color.brandGreen : Color.clear)
                .cornerRadius(6)
        }
    }

    // MARK: - Linescore
    private func linescoreGrid(_ bx: Boxscore) -> some View {
        let innings = bx.linescore?.innings ?? []
        let inningCount = max(innings.count, 9)

        return VStack(spacing: 0) {
            // Header: "Linescore" + status badge
            HStack {
                Text("LINESCORE")
                    .scaledFont(size: 10, weight: .bold, design: .monospaced)
                    .foregroundColor(.brandTextDim)
                    .kerning(1.0)
                Spacer()
                Text(game.status.uppercased())
                    .scaledFont(size: 9, weight: .bold, design: .monospaced)
                    .foregroundColor(game.isLive ? .brandGreen : .brandTextDim)
                    .kerning(1.0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider().background(Color.brandBorder)

            HStack(spacing: 0) {
                Text("")
                    .frame(width: 44, alignment: .leading)
                ForEach(1...inningCount, id: \.self) { n in
                    Text("\(n)")
                        .frame(width: 22)
                }
                Text("R").frame(width: 26)
                Text("H").frame(width: 26)
                Text("E").frame(width: 26)
            }
            .scaledFont(size: 9, weight: .bold, design: .monospaced)
            .foregroundColor(.brandTextDim)
            .padding(.vertical, 8)

            Divider().background(Color.brandBorder)

            lineRow(label: game.away.abbr, innings: innings, inningCount: inningCount,
                    value: { $0.away }, totals: bx.linescore?.away)

            Divider().background(Color.brandBorder)

            lineRow(label: game.home.abbr, innings: innings, inningCount: inningCount,
                    value: { $0.home }, totals: bx.linescore?.home)
        }
        .background(Color.brandSurface)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.brandBorder, lineWidth: 1))
    }

    private func lineRow(
        label: String,
        innings: [InningLine],
        inningCount: Int,
        value: @escaping (InningLine) -> Int?,
        totals: Boxscore.BoxscoreLinescore.LineTotals?
    ) -> some View {
        HStack(spacing: 0) {
            Text(label)
                .scaledFont(size: 11, weight: .bold, design: .monospaced)
                .foregroundColor(.brandText)
                .frame(width: 44, alignment: .leading)

            ForEach(1...inningCount, id: \.self) { n in
                let line = innings.first(where: { $0.num == n })
                let v = line.flatMap(value)
                Text(v.map { "\($0)" } ?? (line == nil ? "" : "X"))
                    .frame(width: 22)
            }

            Text("\(totals?.runs ?? 0)")
                .fontWeight(.bold)
                .foregroundColor(.brandGreen)
                .frame(width: 26)
            Text("\(totals?.hits ?? 0)").frame(width: 26)
            Text("\(totals?.errors ?? 0)").frame(width: 26)
        }
        .scaledFont(size: 11, design: .monospaced)
        .foregroundColor(.brandText)
        .padding(.vertical, 9)
    }

    // MARK: - Batting table
    private func battingTable(_ players: [Boxscore.BoxscorePlayer]) -> some View {
        VStack(spacing: 0) {
            // Card header: "Batting" + away/home toggle
            HStack {
                Text("BATTING")
                    .scaledFont(size: 10, weight: .bold, design: .monospaced)
                    .foregroundColor(.brandTextDim)
                    .kerning(1.0)
                Spacer()
                sideToggle
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider().background(Color.brandBorder)

            // Column header
            HStack(spacing: 0) {
                Text("Batter")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("AB").frame(width: 28)
                Text("R").frame(width: 22)
                Text("H").frame(width: 22)
                Text("RBI").frame(width: 32)
                Text("HR").frame(width: 24)
                Text("BB").frame(width: 26)
                Text("K").frame(width: 22)
                Text("AVG").frame(width: 38)
            }
            .scaledFont(size: 9, weight: .bold, design: .monospaced)
            .foregroundColor(.brandTextDim)
            .kerning(1.0)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider().background(Color.brandBorder)

            if players.isEmpty {
                Text("No batting data")
                    .scaledFont(size: 11, design: .monospaced)
                    .foregroundColor(.brandTextDim)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
            } else {
                ForEach(Array(players.enumerated()), id: \.offset) { idx, p in
                    if idx > 0 {
                        Divider().background(Color.brandBorder.opacity(0.5))
                    }
                    HStack(spacing: 0) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(p.name ?? "—")
                                .scaledFont(size: 12, weight: .semibold, design: .monospaced)
                                .foregroundColor(.brandText)
                                .lineLimit(1)
                            if let pos = p.pos {
                                Text(pos)
                                    .scaledFont(size: 9, design: .monospaced)
                                    .foregroundColor(.brandTextDim)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Text("\(p.ab ?? 0)")
                            .foregroundColor(.brandTextMuted)
                            .frame(width: 28)
                        statCell(p.r, width: 22, color: .brandBlue)
                        statCell(p.h, width: 22, color: .brandText, bold: true)
                        statCell(p.rbi, width: 32, color: .brandAmber)
                        statCell(p.hr, width: 24, color: .brandAmber)
                        Text("\(p.bb ?? 0)")
                            .foregroundColor(.brandTextMuted)
                            .frame(width: 26)
                        statCell(p.k, width: 22, color: .brandRed)
                        Text(p.avg ?? "—")
                            .foregroundColor(.brandTextMuted)
                            .frame(width: 38)
                    }
                    .scaledFont(size: 11, design: .monospaced)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
            }
        }
        .background(Color.brandSurface)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.brandBorder, lineWidth: 1))
    }

    /// Renders a numeric stat cell, highlighted in `color` (and bold) when the
    /// value is greater than zero, otherwise dim/muted — matching the web app's
    /// emphasis on notable batting/pitching events.
    private func statCell(_ value: Int?, width: CGFloat, color: Color, bold: Bool = false) -> some View {
        let v = value ?? 0
        return Text("\(v)")
            .scaledFont(size: 11, weight: (v > 0 && bold) ? .bold : .regular, design: .monospaced)
            .foregroundColor(v > 0 ? color : .brandTextMuted)
            .frame(width: width)
    }

    // MARK: - Pitching table
    private func pitchingTable(_ players: [Boxscore.BoxscorePlayer], teamAbbr: String) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text("PITCHING · \(teamAbbr)")
                    .scaledFont(size: 10, weight: .bold, design: .monospaced)
                    .foregroundColor(.brandTextDim)
                    .kerning(1.0)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider().background(Color.brandBorder)

            HStack(spacing: 0) {
                Text("Pitcher")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("IP").frame(width: 32)
                Text("H").frame(width: 22)
                Text("R").frame(width: 22)
                Text("ER").frame(width: 26)
                Text("BB").frame(width: 26)
                Text("K").frame(width: 22)
                Text("PC").frame(width: 28)
                Text("ERA").frame(width: 38)
            }
            .scaledFont(size: 9, weight: .bold, design: .monospaced)
            .foregroundColor(.brandTextDim)
            .kerning(1.0)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider().background(Color.brandBorder)

            if players.isEmpty {
                Text("No pitching data")
                    .scaledFont(size: 11, design: .monospaced)
                    .foregroundColor(.brandTextDim)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
            } else {
                ForEach(Array(players.enumerated()), id: \.offset) { idx, p in
                    if idx > 0 {
                        Divider().background(Color.brandBorder.opacity(0.5))
                    }
                    HStack(spacing: 0) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(p.name ?? "—")
                                .scaledFont(size: 12, weight: .semibold, design: .monospaced)
                                .foregroundColor(.brandText)
                                .lineLimit(1)
                            if let pos = p.pos {
                                Text(pos)
                                    .scaledFont(size: 9, design: .monospaced)
                                    .foregroundColor(.brandTextDim)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Text(p.ip ?? "—")
                            .foregroundColor(.brandTextMuted)
                            .frame(width: 32)
                        Text("\(p.h ?? 0)")
                            .foregroundColor(.brandTextMuted)
                            .frame(width: 22)
                        statCell(p.r, width: 22, color: .brandRed)
                        statCell(p.er, width: 26, color: .brandRed)
                        Text("\(p.bb ?? 0)")
                            .foregroundColor(.brandTextMuted)
                            .frame(width: 26)
                        statCell(p.k, width: 22, color: .brandGreen)
                        Text("\(p.pc ?? 0)")
                            .foregroundColor(.brandTextMuted)
                            .frame(width: 28)
                        Text(p.era ?? "—")
                            .foregroundColor(.brandTextMuted)
                            .frame(width: 38)
                    }
                    .scaledFont(size: 11, design: .monospaced)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
            }
        }
        .background(Color.brandSurface)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.brandBorder, lineWidth: 1))
    }
}
