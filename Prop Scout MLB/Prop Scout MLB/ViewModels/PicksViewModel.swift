import Foundation
import Combine

final class PicksViewModel: ObservableObject {
    @Published var picks: [Pick] = []
    @Published var stats: PicksStats? = nil
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var selectedDays: Int = 0   // 0 = all-time, 7, 30

    // Picks grouped by slateDate descending
    var groupedPicks: [(date: String, picks: [Pick])] {
        let sorted = picks.sorted { $0.dateKey > $1.dateKey }
        var groups: [(date: String, picks: [Pick])] = []
        for pick in sorted {
            if let idx = groups.firstIndex(where: { $0.date == pick.dateKey }) {
                groups[idx].picks.append(pick)
            } else {
                groups.append((date: pick.dateKey, picks: [pick]))
            }
        }
        return groups
    }

    // MARK: - Load all
    func load() async {
        DispatchQueue.main.async { self.isLoading = true; self.errorMessage = nil }
        async let picksTask: PicksResponse = APIClient.shared.get(
            path: "\(Endpoints.picks)?days=\(selectedDays)"
        )
        async let statsTask: PicksStats = APIClient.shared.get(
            path: "\(Endpoints.picksStats)?days=\(selectedDays)"
        )
        do {
            let (picksResp, statsResp) = try await (picksTask, statsTask)
            let loadedPicks = picksResp.picks.filter { $0.voided != true }
            DispatchQueue.main.async {
                self.picks = loadedPicks
                self.stats = statsResp
                self.isLoading = false
            }
        } catch let e as APIError {
            DispatchQueue.main.async { self.errorMessage = e.errorDescription; self.isLoading = false }
        } catch {
            DispatchQueue.main.async { self.errorMessage = error.localizedDescription; self.isLoading = false }
        }
    }

    // MARK: - Log pick
    func logPick(_ request: LogPickRequest) async throws -> String {
        struct LogResponse: Decodable { let ok: Bool?; let id: String }
        let resp: LogResponse = try await APIClient.shared.post(path: Endpoints.picks, body: request)
        await load()
        return resp.id
    }

    // MARK: - Void pick
    func voidPick(id: String) async {
        do {
            let _: OkResponse = try await APIClient.shared.patch(
                path: Endpoints.pickVoid(id: id),
                body: EmptyBody()
            )
            DispatchQueue.main.async {
                self.picks.removeAll { $0.id == id }
            }
        } catch {}
    }

    // MARK: - Manual grade
    func grade(pick: Pick, hit: Bool) async {
        do {
            let req = GradePickRequest(resultHit: hit, actualStat: nil, gradeStatus: nil)
            let _: OkResponse = try await APIClient.shared.patch(
                path: Endpoints.pickGrade(id: pick.id),
                body: req
            )
            await load()
        } catch {}
    }

    // MARK: - Auto-grade (fetches its own data)
    @Published var isGrading = false

    func autoGrade() async {
        let pending = picks.filter { $0.isPending }
        guard !pending.isEmpty else { return }

        DispatchQueue.main.async { self.isGrading = true }
        defer { DispatchQueue.main.async { self.isGrading = false } }

        let gameMarkets = Set(["ml","spread","total","nrfi","f5ml","f5spread"])

        // 1. Seed gamePks from game market picks (playerId IS the gamePk)
        var allGamePks: Set<Int> = []
        for pick in pending {
            if gameMarkets.contains(pick.market.lowercased()),
               let pk = Int(pick.playerId ?? "") {
                allGamePks.insert(pk)
            }
        }

        // 2. For prop picks, fetch the slate bundle for each unique date to get gamePks.
        //    This also handles historical backfill — picks from past dates resolve via
        //    their own date's bundle.
        let propDates = Set(
            pending
                .filter { !gameMarkets.contains($0.market.lowercased()) }
                .map { $0.dateKey }
        )

        if !propDates.isEmpty {
            await withTaskGroup(of: [Int].self) { group in
                for date in propDates {
                    group.addTask {
                        let path = "\(Endpoints.slateBundle)?date=\(date)"
                        if let bundle: SlateBundle = try? await APIClient.shared.get(path: path) {
                            return bundle.schedule.map { $0.gamePk }
                        }
                        return []
                    }
                }
                for await pks in group { pks.forEach { allGamePks.insert($0) } }
            }
        }

        // 3. Fetch linescores + boxscores concurrently (safe via task group return values)
        var linescores: [Int: LinescoreData] = [:]
        var boxscores:  [Int: Boxscore]      = [:]

        await withTaskGroup(of: (Int, LinescoreData?, Boxscore?).self) { group in
            for pk in allGamePks {
                group.addTask {
                    async let ls: LinescoreData? = try? APIClient.shared.get(
                        path: Endpoints.linescore(gamePk: pk))
                    async let bs: Boxscore? = try? APIClient.shared.get(
                        path: Endpoints.boxscore(gamePk: pk))
                    return await (pk, ls, bs)
                }
            }
            for await (pk, ls, bs) in group {
                if let ls { linescores[pk] = ls }
                if let bs { boxscores[pk] = bs }
            }
        }

        // 4. Grade

        // 4. Grade
        await gradeAllPending(boxscores: boxscores, linescores: linescores)
    }

    func gradeAllPending(boxscores: [Int: Boxscore], linescores: [Int: LinescoreData]) async {
        let pending = picks.filter { $0.isPending }
        for pick in pending {
            guard let request = PickGradingEngine.grade(
                pick: pick,
                boxscores: boxscores,
                linescores: linescores
            ) else { continue }

            let _: OkResponse? = try? await APIClient.shared.patch(
                path: Endpoints.pickGrade(id: pick.id),
                body: request
            )
        }

        await load()
    }

    // MARK: - Filter change
    func setDays(_ days: Int) async {
        DispatchQueue.main.async { self.selectedDays = days }
        await load()
    }
}

private struct EmptyBody: Encodable {}
