import SwiftUI

struct GameArsenalView: View {
    let game: SlateGame
    @ObservedObject var vm: GameDetailViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // SP toggle
                spToggle
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                if let arsenal = vm.currentArsenal, let pitches = arsenal.arsenal, !pitches.isEmpty {
                    // Savant badge
                    HStack {
                        Text("— \(pitcherName)'S ARSENAL VS \(opponentAbbr) LINEUP")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.brandTextDim)
                        Spacer()
                        Text("SAVANT LIVE")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(.brandGreen)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.brandGreen.opacity(0.12))
                            .cornerRadius(4)
                    }
                    .padding(.horizontal, 16)

                    ForEach(pitches) { pitch in
                        PitchCardView(pitch: pitch)
                            .padding(.horizontal, 16)
                    }
                } else {
                    Text(vm.currentArsenal == nil ? "Loading arsenal…" : "Arsenal data unavailable")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.brandTextDim)
                        .frame(maxWidth: .infinity)
                        .padding(24)
                        .background(Color.brandSurface)
                        .cornerRadius(10)
                        .padding(.horizontal, 16)
                }

                Spacer(minLength: 20)
            }
        }
        .background(Color.brandBackground)
    }

    private var spToggle: some View {
        HStack(spacing: 0) {
            spButton("\(game.away.abbr) SP", side: .away)
            spButton("\(game.home.abbr) SP", side: .home)
        }
        .background(Color.brandSurface2)
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.brandBorder, lineWidth: 1))
    }

    private func spButton(_ label: String, side: GameDetailViewModel.SPSide) -> some View {
        Button { vm.selectedSPSide = side } label: {
            Text(label)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(vm.selectedSPSide == side ? .brandBackground : .brandTextMuted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(vm.selectedSPSide == side ? Color.brandGreen : Color.clear)
                .cornerRadius(7)
        }
    }

    private var pitcherName: String {
        let p = vm.selectedSPSide == .away ? game.probablePitchers?.away : game.probablePitchers?.home
        return p?.name.components(separatedBy: " ").last?.uppercased() ?? "SP"
    }

    private var opponentAbbr: String {
        vm.selectedSPSide == .away ? game.home.abbr : game.away.abbr
    }
}

// MARK: - Individual pitch card
struct PitchCardView: View {
    let pitch: PitchInfo

    private var qualityColor: Color {
        switch pitch.quality {
        case .weakSpot: return .brandRed
        case .handles:  return .brandGreen
        case .neutral:  return .brandAmber
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header: abbr chip + name + velo + usage + quality badge
            HStack(spacing: 10) {
                pitchChip
                VStack(alignment: .leading, spacing: 2) {
                    Text(pitch.displayName)
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(.brandText)
                    HStack(spacing: 4) {
                        if let velo = pitch.avgVelo {
                            Text(String(format: "%.1f mph", velo))
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.brandTextMuted)
                            // YoY velo delta badge
                            if let delta = pitch.veloDelta, abs(delta) >= 0.3 {
                                let isDown = delta < 0
                                HStack(spacing: 2) {
                                    Image(systemName: isDown ? "arrow.down" : "arrow.up")
                                        .font(.system(size: 8))
                                    Text(String(format: "%.1f", abs(delta)))
                                        .font(.system(size: 9, design: .monospaced))
                                }
                                .foregroundColor(isDown ? .brandRed : .brandAmber)
                            }
                        }
                        if let usage = pitch.usagePct {
                            Text("\(pitch.avgVelo != nil ? "· " : "")\(Int(usage))% usage")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.brandTextMuted)
                        }
                        if let whiff = pitch.whiffRate {
                            Text("· \(Int(whiff))% whiff")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.brandTextMuted)
                        }
                    }
                }
                Spacer()
                // Quality badge
                Text(pitch.quality.label)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(qualityColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(qualityColor.opacity(0.12))
                    .cornerRadius(4)
            }

            // Usage bar
            if let usage = pitch.usagePct {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2).fill(Color.brandBorder2).frame(height: 4)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(qualityColor)
                            .frame(width: geo.size.width * CGFloat(usage) / 100, height: 4)
                    }
                }
                .frame(height: 4)
            }

            // Stats row: BATTER AVG + BATTER WHIFF + SLG
            HStack(spacing: 12) {
                if let avg = pitch.avg {
                    statMini(label: "BATTER AVG", value: avg, color: qualityColor)
                }
                if let whiff = pitch.whiffRate {
                    statMini(label: "BATTER WHIFF", value: "\(Int(whiff))%", color: .brandTextMuted)
                }
                if let slg = pitch.slg {
                    statMini(label: "SLG", value: slg, color: .brandTextMuted)
                }
            }

            // Warning chip (heavy usage / risk)
            if let warn = pitch.warning, !warn.isEmpty {
                HStack(spacing: 5) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 9))
                        .foregroundColor(.brandAmber)
                    Text(warn)
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundColor(.brandAmber)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.brandAmber.opacity(0.10))
                .cornerRadius(6)
            }

            // Insight / matchup note
            if let note = pitch.insight, !note.isEmpty {
                HStack(spacing: 5) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 10))
                        .foregroundColor(.brandCyan)
                    Text(note)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.brandTextMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.brandSurface2)
                .cornerRadius(6)
            }
        }
        .padding(14)
        .background(Color.brandSurface)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.brandBorder, lineWidth: 1))
    }

    private var pitchChip: some View {
        Text(pitch.abbr ?? "?")
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .foregroundColor(.brandBackground)
            .frame(width: 32, height: 32)
            .background(qualityColor)
            .cornerRadius(6)
    }

    private func statMini(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 8, design: .monospaced))
                .foregroundColor(.brandTextDim)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.brandSurface2)
        .cornerRadius(7)
    }
}
