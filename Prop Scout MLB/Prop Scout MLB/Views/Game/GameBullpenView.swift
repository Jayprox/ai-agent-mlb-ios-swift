import SwiftUI

struct GameBullpenView: View {
    let game: SlateGame
    @ObservedObject var vm: GameDetailViewModel

    @State private var awayExpanded = false
    @State private var homeExpanded = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if let bp = vm.bullpen {
                    Text("— BULLPEN STRENGTH & FATIGUE")
                        .scaledFont(size: 10, weight: .bold, design: .monospaced)
                        .foregroundColor(.brandTextDim)
                        .kerning(1)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)

                    // Side-by-side strength/fatigue summary
                    HStack(alignment: .top, spacing: 12) {
                        strengthCard(abbr: game.away.abbr, team: bp.away)
                        strengthCard(abbr: game.home.abbr, team: bp.home)
                    }
                    .padding(.horizontal, 16)

                    // Per-team detail cards
                    bullpenDetailCard(
                        abbr: game.away.abbr, team: bp.away,
                        expanded: $awayExpanded
                    )
                    .padding(.horizontal, 16)

                    bullpenDetailCard(
                        abbr: game.home.abbr, team: bp.home,
                        expanded: $homeExpanded
                    )
                    .padding(.horizontal, 16)
                } else {
                    Text(vm.isLoading ? "Loading bullpen…" : "Bullpen data unavailable")
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

    // MARK: - Strength & fatigue summary card
    private func strengthCard(abbr: String, team: BullpenData.BullpenTeam?) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(abbr) BULLPEN")
                .scaledFont(size: 9, weight: .bold, design: .monospaced)
                .foregroundColor(.brandTextDim)
                .kerning(1)

            HStack {
                Text("Grade")
                    .scaledFont(size: 11, design: .monospaced)
                    .foregroundColor(.brandTextMuted)
                Spacer()
                if let grade = team?.grade {
                    Text(grade)
                        .scaledFont(size: 18, weight: .bold, design: .monospaced)
                        .foregroundColor(gradeColor(team))
                }
            }

            HStack {
                Text("Fatigue")
                    .scaledFont(size: 11, design: .monospaced)
                    .foregroundColor(.brandTextMuted)
                Spacer()
                if let fatigue = team?.fatigueLevel {
                    Text(fatigue)
                        .scaledFont(size: 10, weight: .bold, design: .monospaced)
                        .foregroundColor(fatigueColor(fatigue))
                }
            }

            if let note = team?.note, !note.isEmpty {
                Divider().background(Color.brandBorder)
                Text(note)
                    .scaledFont(size: 10, design: .monospaced)
                    .foregroundColor(.brandTextDim)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.brandSurface)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.brandBorder, lineWidth: 1))
    }

    // MARK: - Per-team detail card
    private func bullpenDetailCard(
        abbr: String, team: BullpenData.BullpenTeam?, expanded: Binding<Bool>
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title row + grade/fatigue badges
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(abbr) Bullpen")
                        .scaledFont(size: 14, weight: .bold, design: .monospaced)
                        .foregroundColor(.brandText)
                    if let team, !team.depthSummary.isEmpty {
                        Text(team.depthSummary)
                            .scaledFont(size: 11, design: .monospaced)
                            .foregroundColor(.brandTextDim)
                    }
                }
                Spacer()
                HStack(spacing: 6) {
                    if let grade = team?.grade {
                        Text(grade)
                            .scaledFont(size: 13, weight: .bold, design: .monospaced)
                            .foregroundColor(gradeColor(team))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(gradeColor(team).opacity(0.12))
                            .overlay(RoundedRectangle(cornerRadius: 5).stroke(gradeColor(team).opacity(0.4), lineWidth: 1))
                            .cornerRadius(5)
                    }
                    if let fatigue = team?.fatigueLevel {
                        Text(fatigue)
                            .scaledFont(size: 9, weight: .bold, design: .monospaced)
                            .foregroundColor(fatigueColor(fatigue))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(fatigueColor(fatigue).opacity(0.12))
                            .cornerRadius(5)
                    }
                }
            }

            // Stat tiles: REST DAYS / P LAST 3G / DEPTH / L/R
            HStack(spacing: 8) {
                statTile(value: team?.restDays.map { "\($0)" } ?? "—", label: "REST DAYS", color: .brandText)
                statTile(value: team?.pitchesLast3.map { "\($0)" } ?? "—", label: "P LAST 3G", color: .brandText)
                statTile(value: team?.setupDepth ?? "—", label: "DEPTH", color: .brandAmber)
                statTile(value: team?.lrBalance ?? "—", label: "L/R", color: .brandAmber)
            }

            // Insight line
            if let lean = team?.lean, !lean.isEmpty {
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.brandAmber)
                        .frame(width: 3)
                    Text(lean)
                        .scaledFont(size: 11, design: .monospaced)
                        .foregroundColor(.brandTextMuted)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 9)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                .background(Color.brandSurface2)
                .cornerRadius(6)
            }

            // Collapsible relievers section
            if let relievers = team?.relievers, !relievers.isEmpty {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        expanded.wrappedValue.toggle()
                    }
                } label: {
                    HStack {
                        Text("RELIEVERS (\(relievers.count))")
                            .scaledFont(size: 10, weight: .bold, design: .monospaced)
                            .foregroundColor(.brandTextDim)
                            .kerning(1)
                        Spacer()
                        Text(expanded.wrappedValue ? "▲ hide" : "▼ show")
                            .scaledFont(size: 10, design: .monospaced)
                            .foregroundColor(.brandTextDim)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.brandSurface2)
                    .cornerRadius(8)
                }

                if expanded.wrappedValue {
                    VStack(spacing: 6) {
                        ForEach(relievers) { r in
                            relieverRow(r)
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(Color.brandSurface)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.brandBorder, lineWidth: 1))
    }

    // MARK: - Stat tile
    private func statTile(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .scaledFont(size: 13, weight: .bold, design: .monospaced)
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .scaledFont(size: 8, weight: .bold, design: .monospaced)
                .foregroundColor(.brandTextDim)
                .kerning(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.brandSurface2)
        .cornerRadius(8)
    }

    // MARK: - Reliever row
    private func relieverRow(_ r: BullpenData.Reliever) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            // Name with role and hand
            HStack(spacing: 4) {
                Text(r.name ?? "—")
                    .scaledFont(size: 12, weight: .semibold, design: .monospaced)
                    .foregroundColor(.brandText)
                if let role = r.role {
                    Text(role)
                        .scaledFont(size: 8, weight: .bold, design: .monospaced)
                        .foregroundColor(.brandCyan)
                }
                if let hand = r.hand {
                    Text(hand)
                        .scaledFont(size: 8, design: .monospaced)
                        .foregroundColor(.brandTextDim)
                }
                Spacer()
            }

            // Last app and status
            HStack(spacing: 6) {
                if let lastApp = r.lastApp {
                    Text(lastApp)
                        .scaledFont(size: 9, design: .monospaced)
                        .foregroundColor(.brandTextDim)
                }
                if let status = r.status {
                    Text(status)
                        .scaledFont(size: 8, weight: .bold, design: .monospaced)
                        .foregroundColor(status.uppercased() == "FRESH" ? .brandGreen : .brandRed)
                }
                Spacer()
            }

            // Stats row
            HStack(spacing: 8) {
                if let era = r.era { statChip("ERA", era) }
                if let whip = r.whip { statChip("WHIP", whip) }
                if let pitches = r.pitches { statChip("PITCHES", "\(pitches)") }
                if let k9 = r.k9 { statChip("K/9", k9) }
                if let bb9 = r.bb9 { statChip("BB/9", bb9) }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.brandSurface2)
        .cornerRadius(8)
    }

    private func statChip(_ label: String, _ value: String) -> some View {
        VStack(spacing: 1) {
            Text(value)
                .scaledFont(size: 11, weight: .semibold, design: .monospaced)
                .foregroundColor(.brandText)
            Text(label)
                .scaledFont(size: 8, design: .monospaced)
                .foregroundColor(.brandTextDim)
        }
        .frame(width: 40)
    }

    // MARK: - Color helpers
    private func gradeColor(_ team: BullpenData.BullpenTeam?) -> Color {
        if let hex = team?.gradeColor { return Color(hex: hex) }
        switch (team?.grade ?? "").uppercased().first {
        case "A": return .brandGreen
        case "B": return .brandCyan
        case "C": return .brandAmber
        default:  return .brandRed
        }
    }

    private func fatigueColor(_ level: String) -> Color {
        switch level.uppercased() {
        case "LOW":      return .brandGreen
        case "MODERATE": return .brandAmber
        case "HIGH":     return .brandRed
        default:         return .brandTextMuted
        }
    }
}
