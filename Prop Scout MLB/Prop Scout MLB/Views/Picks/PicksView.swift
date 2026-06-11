import SwiftUI

struct PicksView: View {
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var vm: PicksViewModel
    @State private var showLogSheet = false
    @State private var showSettings = false

    private let dayOptions: [(label: String, days: Int)] = [
        ("ALL", 0), ("7D", 7), ("30D", 30)
    ]

    var body: some View {
        NavigationView {
            ZStack {
                Color.brandBackground.ignoresSafeArea()

                if vm.isLoading && vm.picks.isEmpty {
                    PicksSkeletonList().padding(.top, 8)
                } else {
                    mainContent
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { titleToolbar }
        }
        .task {
            await vm.load()
            await vm.autoGrade()
        }
        .sheet(isPresented: $showLogSheet) {
            LogPickSheet(vm: vm)
                .presentationDetents([.large])
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .colorScheme(.dark)
    }

    // MARK: - Main content
    private var mainContent: some View {
        ScrollView {
            LazyVStack(spacing: 12, pinnedViews: []) {
                // Header
                header
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                // Filter tabs
                filterTabs
                    .padding(.horizontal, 16)

                // Stats tiles
                if let stats = vm.stats {
                    statsTiles(stats)
                        .padding(.horizontal, 16)
                }

                // Error
                if let error = vm.errorMessage {
                    Text(error)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.brandRed)
                        .padding(.horizontal, 16)
                }

                // Picks grouped by date
                if vm.picks.isEmpty && !vm.isLoading {
                    emptyState
                } else {
                    ForEach(vm.groupedPicks, id: \.date) { group in
                        dateSection(group)
                    }
                }

                Spacer(minLength: 20)
            }
        }
        .refreshable { await vm.load() }
    }

    // MARK: - Header
    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("📋 PICKS")
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(.brandText)
                .kerning(1)
            Text("Logged board and props plays for \(auth.username.isEmpty ? "leadoffkaiba" : auth.username)")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.brandTextMuted)
        }
    }

    // MARK: - Filter tabs
    private var filterTabs: some View {
        HStack(spacing: 8) {
            ForEach(dayOptions, id: \.days) { option in
                Button {
                    Task { await vm.setDays(option.days) }
                } label: {
                    Text(option.label)
                        .font(.system(size: 12, weight: vm.selectedDays == option.days ? .bold : .medium,
                                      design: .monospaced))
                        .foregroundColor(vm.selectedDays == option.days ? .white : .brandTextMuted)
                        .padding(.vertical, 7)
                        .padding(.horizontal, 16)
                        .background(vm.selectedDays == option.days ? Color.brandBlue : Color.brandSurface2)
                        .cornerRadius(20)
                }
            }
            Spacer()
        }
    }

    // MARK: - Stats tiles
    private func statsTiles(_ stats: PicksStats) -> some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
            statTile(
                label: "RECORD",
                value: stats.record,
                sub: "\(stats.pending) pending",
                valueColor: .brandText
            )
            statTile(
                label: "HIT RATE",
                value: stats.hitRateDisplay,
                sub: nil,
                valueColor: .brandGreen
            )
            statTile(
                label: "P&L",
                value: stats.pnlDisplay,
                sub: nil,
                valueColor: (stats.totalPnl ?? 0) >= 0 ? .brandGreen : .brandRed
            )
        }
    }

    private func statTile(label: String, value: String, sub: String?, valueColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(.brandTextDim)
                .kerning(1.2)
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(valueColor)
            if let sub {
                Text(sub)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.brandTextDim)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.brandSurface)
        .cornerRadius(10)
    }

    // MARK: - Date section
    private func dateSection(_ group: (date: String, picks: [Pick])) -> some View {
        PickDateSectionView(
            group: group,
            isToday: group.date == todayKey,
            onVoid: { id in Task { await vm.voidPick(id: id) } },
            onGrade: { pick, hit in Task { await vm.grade(pick: pick, hit: hit) } }
        )
    }

    private var todayKey: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "Pacific/Honolulu")
        return f.string(from: Date())
    }

    // MARK: - Empty state
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "note.text")
                .font(.system(size: 32))
                .foregroundColor(.brandTextDim)
                .padding(.top, 40)
            Text("No picks logged yet")
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(.brandTextMuted)
            Button("Log your first pick") { showLogSheet = true }
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(.brandGreen)
        }
    }

    // MARK: - Toolbar
    private var titleToolbar: some ToolbarContent {
        Group {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 6) {
                    Text("🗒️")
                        .font(.system(size: 14))
                    Text("Picks")
                        .font(.system(size: 17, weight: .bold, design: .monospaced))
                        .foregroundColor(.brandText)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 14) {
                    // Auto-grade pending picks
                    if vm.picks.contains(where: { $0.isPending }) {
                        Button {
                            Task { await vm.autoGrade() }
                        } label: {
                            if vm.isGrading {
                                ProgressView().tint(.brandAmber).scaleEffect(0.8)
                            } else {
                                Image(systemName: "checkmark.circle")
                                    .font(.system(size: 16))
                                    .foregroundColor(.brandAmber)
                            }
                        }
                        .disabled(vm.isGrading)
                    }
                    Button {
                        showLogSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.brandGreen)
                    }
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 16))
                            .foregroundColor(.brandTextMuted)
                    }
                }
            }
        }
    }
}

// MARK: - Collapsible date section
private struct PickDateSectionView: View {
    let group: (date: String, picks: [Pick])
    let isToday: Bool
    let onVoid: (String) -> Void
    let onGrade: (Pick, Bool) -> Void

    @State private var isExpanded: Bool

    init(group: (date: String, picks: [Pick]),
         isToday: Bool,
         onVoid: @escaping (String) -> Void,
         onGrade: @escaping (Pick, Bool) -> Void) {
        self.group   = group
        self.isToday = isToday
        self.onVoid  = onVoid
        self.onGrade = onGrade
        // Today starts expanded; past dates start collapsed
        _isExpanded = State(initialValue: isToday)
    }

    private var record: (hits: Int, misses: Int, pending: Int) {
        let hits    = group.picks.filter { $0.isHit }.count
        let misses  = group.picks.filter { $0.isMiss }.count
        let pending = group.picks.filter { $0.isPending }.count
        return (hits, misses, pending)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header row — tappable
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() }
            } label: {
                HStack(spacing: 8) {
                    Text(group.picks.first?.formattedDate ?? group.date)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.brandTextDim)
                        .kerning(1.2)

                    Spacer()

                    // Inline record summary
                    let r = record
                    if r.hits + r.misses > 0 {
                        Text("\(r.hits)-\(r.misses)")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundColor(r.hits >= r.misses ? .brandGreen : .brandRed)
                    }
                    if r.pending > 0 {
                        Text("\(r.pending) pending")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.brandTextDim)
                    }

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10))
                        .foregroundColor(.brandTextDim)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)

            // Pick cards
            if isExpanded {
                VStack(spacing: 8) {
                    ForEach(group.picks) { pick in
                        PickCardView(
                            pick: pick,
                            onVoid: { onVoid(pick.id) },
                            onGrade: { hit in onGrade(pick, hit) }
                        )
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.top, 8)
                .transition(.opacity)
            }
        }
    }
}
