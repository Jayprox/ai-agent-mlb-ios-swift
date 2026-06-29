import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // MARK: - Section 1: Reading the Slate Card
                    helpSection(
                        title: "Reading the Slate Card",
                        items: [
                            ("Selected card", "Active game is highlighted in green — tap any card to open."),
                            ("O/U", "The total runs line. Green dot = live odds loaded. Bet over or under."),
                            ("ML", "Moneyline — odds to win outright. Away team first. + = underdog, − = favorite."),
                            ("O/U Odds", "Juice on the over/under. Uneven odds = book shading one side, often where sharp money sits."),
                            ("RL", "Runline — always ±1.5 runs. Dog gets +1.5, favorite gives −1.5."),
                            ("NRFI badge", "Model leans No Run First Inning at 62%+ confidence. Only shown on green-bordered cards."),
                            ("Temperature / DOME", "Live weather at game time. Cold suppresses offense. DOME = climate-controlled retractable roof."),
                            ("FINAL score", "Completed games: final score, O/U result, ML winner, RL result, and NRFI/YRFI chip."),
                            ("LIVE score", "In-progress: away–home runs, ▲/▼ for top/bottom of inning, current inning number."),
                            ("SP IL", "A probable starting pitcher has an active IL placement. Bullpen game risk — verify before betting.")
                        ],
                        accentColor: .brandGreen
                    )

                    // MARK: - Section 2: Color Guide
                    helpSection(
                        title: "Color Guide",
                        items: [
                            ("Green", "Pitcher Edge (score < 35). Pitcher has the advantage. Good for K props and unders."),
                            ("Yellow", "Neutral (score 35–54). No clear edge. Look for other factors before betting."),
                            ("Red", "Batter Edge (score 55+). Batter has the advantage. Good for hit, TB, and HR props."),
                            ("Purple", "Chat & scout tools. Used for Chat and AI-driven views.")
                        ],
                        accentColor: .brandAmber
                    )

                    // MARK: - Section 3: Matchup Score
                    helpSection(
                        title: "How the Matchup Score Works",
                        items: [
                            ("Scoring weights", "AVG (45%) + Whiff rate (35%) + Slugging (20%). Each weighted by pitcher's pitch usage."),
                            ("Pitcher/Batter Wins", "Specific pitch types favoring each side. Even neutral scores have a story."),
                            ("Scouting notes", "Elite contact, Chases in dirt, Severe weakness, Average results — per pitch card."),
                            ("Handedness penalty", "Same-hand matchups (RHP vs RHB) apply 8% score reduction. Opposite-hand = no penalty."),
                            ("Confidence", "0–100% confidence meter. 70%+ is a strong signal worth acting on.")
                        ],
                        accentColor: .brandCyan
                    )

                    // MARK: - Section 4: Overview Tab
                    helpSection(
                        title: "Overview Tab",
                        items: [
                            ("Pitcher Card", "Season ERA, WHIP, K/9, BB/9, sparkline of recent outings, W-L record, clean-start count."),
                            ("Lineup Intel", "Counts RHB, LHB, and switch hitters. Aggregate matchup score. Flags top 3 danger hitters."),
                            ("Game Lean", "NRFI lean derived from both SPs' clean-start rate. Quick read for NRFI props.")
                        ],
                        accentColor: .brandPurple
                    )

                    // MARK: - Section 5: Intel Tab
                    helpSection(
                        title: "Intel Tab",
                        items: [
                            ("Umpire", "Home plate ump with accuracy, vs expected, consistency, and favor/game metrics. ACCURATE or PITCHER UMP badge."),
                            ("Weather", "Temperature, wind direction (field-relative), humidity, roof type, rain chance. All key for props."),
                            ("Park Factors", "HR, Hit, and K factors. Over 1.0 = hitter-friendly. Under 1.0 = pitcher-friendly."),
                            ("Bullpen", "Grade, fatigue, depth, L/R balance. Expand reliever drawer for ERA, WHIP, Pitches, K/9, BB/9."),
                            ("AI Trends", "Claude-powered analysis tuned to the game context and matchups.")
                        ],
                        accentColor: .brandBlue
                    )

                    // MARK: - Section 6: Prop Types
                    helpSection(
                        title: "Prop Types Explained",
                        items: [
                            ("K", "Pitcher strikeouts — Over/Under on batters fanned. High K/9 + green matchup = good over."),
                            ("Outs", "Pitcher outs recorded — 3 outs = 1 inning. A line of 17.5 ≈ 6 innings."),
                            ("Hits", "Batter hits — typically Over 0.5 (at least one hit) or Under 1.5. Red matchup = good over."),
                            ("TB", "Total Bases — single (1), double (2), triple (3), home run (4). Over 1.5 TB is popular."),
                            ("HR", "Home Run — will this batter hit at least one? Power metrics, park factor, pitcher tendencies."),
                            ("NRFI", "No Run First Inning — neither team scores in the 1st. Both SPs with low first-inning rates."),
                            ("RBI", "Runs Batted In — at least one run. Batting order, runners tendencies, extra-base rate.")
                        ],
                        accentColor: .brandGreen
                    )

                    // MARK: - Section 7: Stat Glossary
                    helpSection(
                        title: "Stat Glossary",
                        items: [
                            ("ML", "Moneyline — odds to win outright. +150 = $100 to win $150. −150 = $150 to win $100."),
                            ("RL", "Runline — MLB's point spread, always ±1.5 runs. Price in parentheses is the juice."),
                            ("ERA", "Earned Run Average — runs per 9 innings. <3.00 = elite, 3–4 = solid, 5+ = hittable."),
                            ("WHIP", "Walks + Hits per Inning Pitched. <1.10 = elite, 1.10–1.30 = average, 1.40+ = concerning."),
                            ("K/9", "Strikeouts per 9 innings. 10+ = high strikeout pitcher. Great for K props."),
                            ("BB/9", "Walks per 9 innings. <2.5 = very controlled. 5+ = walk-prone."),
                            ("AVG", "Batting Average — hits / at-bats. .300+ = excellent, .250 = average, <.220 = struggling."),
                            ("OPS", "On-base Plus Slugging. .900+ = elite, .800 = solid, <.700 = below average."),
                            ("SLG", "Slugging Percentage — total bases per at-bat. .500+ = power hitter."),
                            ("IP", "Innings Pitched. Avg 6+ = pitcher works deep into games."),
                            ("HR Factor", "Park Factor for home runs. >1.0 = hitter-friendly, <1.0 = pitcher-friendly.")
                        ],
                        accentColor: .brandAmber
                    )

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Color.brandBackground)
            .navigationTitle("Help & Guide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .scaledFont(size: 18)
                            .foregroundColor(.brandTextMuted)
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    // MARK: - Help Section Component
    private func helpSection(title: String, items: [(String, String)], accentColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header
            HStack {
                Text(title.uppercased())
                    .scaledFont(size: 10, weight: .bold, design: .monospaced)
                    .foregroundColor(.brandTextDim)
                    .kerning(1.2)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.brandSurface2)
            .cornerRadius(10, corners: [.topLeft, .topRight])

            // Section content
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(items.enumerated()), id: \.offset) { idx, item in
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(item.0)
                                .scaledFont(size: 9, weight: .bold, design: .monospaced)
                                .foregroundColor(.black)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(accentColor)
                                .cornerRadius(3)

                            Spacer()
                        }

                        Text(item.1)
                            .scaledFont(size: 10, design: .monospaced)
                            .foregroundColor(.brandTextMuted)
                            .lineSpacing(2)
                    }

                    if idx < items.count - 1 {
                        Divider().background(Color.brandBorder.opacity(0.5))
                    }
                }
            }
            .padding(12)
            .background(Color.brandSurface)
            .cornerRadius(10, corners: [.bottomLeft, .bottomRight])
        }
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.brandBorder, lineWidth: 1))
    }
}

// MARK: - Corner Radius Extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    HelpView()
}
