import Foundation
import Combine

@MainActor
final class GameDetailViewModel: ObservableObject {
    // Pre-loaded from slate bundle
    @Published var odds: OddsData? = nil
    @Published var weather: WeatherData? = nil

    // Fetched on load
    @Published var awayPitcherStats: PitcherStats? = nil
    @Published var homePitcherStats: PitcherStats? = nil
    @Published var awayGamelog: PitcherGamelog? = nil
    @Published var homeGamelog: PitcherGamelog? = nil
    @Published var awayArsenal: ArsenalData? = nil
    @Published var homeArsenal: ArsenalData? = nil
    @Published var awayPitcherSplits: PitcherSplits? = nil
    @Published var homePitcherSplits: PitcherSplits? = nil
    @Published var lineup: LineupData? = nil
    @Published var umpire: UmpireData? = nil
    @Published var nrfi: NRFIDetail? = nil
    @Published var bullpen: BullpenData? = nil
    @Published var linescore: LinescoreData? = nil
    @Published var boxscore: Boxscore? = nil
    @Published var topMatchups: TopMatchupsResponse? = nil
    @Published var injuredIds: Set<Int> = []

    // Intel tab
    @Published var trends: TrendsSummary? = nil
    @Published var isLoadingTrends = false
    @Published var trendsError: String? = nil
    @Published var notes: [ScoutNote] = []
    @Published var isSavingNote = false
    private(set) var gameKey: String = ""

    @Published var isLoading = false
    @Published var loadError: String? = nil

    // Tab state
    @Published var selectedSPSide: SPSide = .away  // Overview + Arsenal SP toggle
    @Published var lineupSide: SPSide = .away       // Lineup side toggle

    enum SPSide { case away, home }

    // MARK: - Load
    func load(game: SlateGame, odds: OddsData?, weather: WeatherData?) async {
        self.odds    = odds
        self.weather = weather
        isLoading    = true
        loadError    = nil

        let awayPk = game.probablePitchers?.away?.id
        let homePk = game.probablePitchers?.home?.id
        let gamePk = game.gamePk
        gameKey = String(gamePk)

        await withTaskGroup(of: Void.self) { group in

            // Lineup
            group.addTask {
                let d: LineupData? = try? await APIClient.shared.get(
                    path: "/api/lineups/\(gamePk)"
                )
                await MainActor.run { self.lineup = d }
            }

            // Umpire
            group.addTask {
                let d: UmpireData? = try? await APIClient.shared.get(
                    path: "/api/umpires/\(gamePk)"
                )
                await MainActor.run { self.umpire = d }
            }

            // NRFI
            group.addTask {
                let d: NRFIDetail? = try? await APIClient.shared.get(
                    path: "/api/nrfi/\(gamePk)"
                )
                await MainActor.run { self.nrfi = d }
            }

            // Top Matchups
            group.addTask {
                let d: TopMatchupsResponse? = try? await APIClient.shared.get(
                    path: "/api/game/\(gamePk)/matchups?limit=9"
                )
                await MainActor.run { self.topMatchups = d }
            }

            // Bullpen
            group.addTask {
                let d: BullpenData? = try? await APIClient.shared.get(
                    path: "/api/bullpen/\(gamePk)"
                )
                await MainActor.run { self.bullpen = d }
            }

            // Linescore
            group.addTask {
                let d: LinescoreData? = try? await APIClient.shared.get(
                    path: Endpoints.linescore(gamePk: gamePk)
                )
                await MainActor.run { self.linescore = d }
            }

            // Boxscore
            group.addTask {
                let d: Boxscore? = try? await APIClient.shared.get(
                    path: Endpoints.boxscore(gamePk: gamePk)
                )
                await MainActor.run { self.boxscore = d }
            }

            // Injuries (active IL placements, last 14 days, all teams)
            group.addTask {
                let d: InjuriesData? = try? await APIClient.shared.get(
                    path: "/api/injuries"
                )
                let ids = Set((d?.injuries ?? []).compactMap { $0.playerId })
                await MainActor.run { self.injuredIds = ids }
            }

            // Away pitcher
            if let pk = awayPk {
                group.addTask {
                    let stats: PitcherStats? = try? await APIClient.shared.get(
                        path: "/api/players/\(pk)/stats?group=pitching"
                    )
                    await MainActor.run { self.awayPitcherStats = stats }
                }
                group.addTask {
                    let log: PitcherGamelog? = try? await APIClient.shared.get(
                        path: "/api/players/\(pk)/gamelog?group=pitching"
                    )
                    await MainActor.run { self.awayGamelog = log }
                }
                group.addTask {
                    let arsenal: ArsenalData? = try? await APIClient.shared.get(
                        path: "/api/arsenal/\(pk)"
                    )
                    await MainActor.run { self.awayArsenal = arsenal }
                }
                group.addTask {
                    let splits: PitcherSplits? = try? await APIClient.shared.get(
                        path: "/api/pitcher-splits/\(pk)"
                    )
                    await MainActor.run { self.awayPitcherSplits = splits }
                }
            }

            // Home pitcher
            if let pk = homePk {
                group.addTask {
                    let stats: PitcherStats? = try? await APIClient.shared.get(
                        path: "/api/players/\(pk)/stats?group=pitching"
                    )
                    await MainActor.run { self.homePitcherStats = stats }
                }
                group.addTask {
                    let log: PitcherGamelog? = try? await APIClient.shared.get(
                        path: "/api/players/\(pk)/gamelog?group=pitching"
                    )
                    await MainActor.run { self.homeGamelog = log }
                }
                group.addTask {
                    let arsenal: ArsenalData? = try? await APIClient.shared.get(
                        path: "/api/arsenal/\(pk)"
                    )
                    await MainActor.run { self.homeArsenal = arsenal }
                }
                group.addTask {
                    let splits: PitcherSplits? = try? await APIClient.shared.get(
                        path: "/api/pitcher-splits/\(pk)"
                    )
                    await MainActor.run { self.homePitcherSplits = splits }
                }
            }
        }

        isLoading = false
    }

    // MARK: - Intel: AI Trends
    func loadTrends() async {
        guard !gameKey.isEmpty, trends == nil, !isLoadingTrends else { return }
        isLoadingTrends = true
        trendsError = nil
        do {
            struct TrendsBody: Encodable { let context: String }
            let result: TrendsSummary = try await APIClient.shared.post(
                path: "/api/trends/\(gameKey)",
                body: TrendsBody(context: "")
            )
            trends = result
        } catch {
            trendsError = "Analysis unavailable"
        }
        isLoadingTrends = false
    }

    // MARK: - Intel: Scout Notes
    func loadNotes() async {
        guard !gameKey.isEmpty else { return }
        let resp: ScoutNoteResponse? = try? await APIClient.shared.get(
            path: "/api/notes/\(gameKey)"
        )
        notes = resp?.notes ?? []
    }

    func saveNote(_ text: String) async {
        guard !gameKey.isEmpty, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        struct NoteBody: Encodable { let note: String }
        isSavingNote = true
        let _: EmptyOK? = try? await APIClient.shared.post(
            path: "/api/notes/\(gameKey)",
            body: NoteBody(note: text.trimmingCharacters(in: .whitespacesAndNewlines))
        )
        isSavingNote = false
        await loadNotes()
    }

    // MARK: - Convenience
    var currentStats:   PitcherStats?    { selectedSPSide == .away ? awayPitcherStats   : homePitcherStats }
    var currentGamelog: PitcherGamelog?  { selectedSPSide == .away ? awayGamelog        : homeGamelog }
    var currentArsenal: ArsenalData?     { selectedSPSide == .away ? awayArsenal        : homeArsenal }
    var currentSplits:  PitcherSplits?   { selectedSPSide == .away ? awayPitcherSplits  : homePitcherSplits }
    var currentLineup:  [LineupBatter]   { (lineupSide == .away ? lineup?.away : lineup?.home) ?? [] }
}
