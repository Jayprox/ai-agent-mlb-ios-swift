import SwiftUI

struct AIBoardView: View {
    @StateObject private var vm = AIBoardViewModel()
    @EnvironmentObject var picksVM: PicksViewModel
    @Environment(\.horizontalSizeClass) var sizeClass

    private var isIpad: Bool {
        sizeClass == .regular
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.brandBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Filter tabs
                    filterBar
                        .background(Color.brandSurface)

                    Divider().background(Color.brandBorder)

                    if vm.isLoading && vm.edges.isEmpty {
                        loadingView
                    } else if let error = vm.errorMessage, vm.edges.isEmpty {
                        errorView(error)
                    } else {
                        edgeList
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { titleToolbar }
        }
        .navigationViewStyle(.stack)
        .task { await vm.load() }
        .colorScheme(.dark)
    }

    // MARK: - Filter bar (Adaptive for iPhone/iPad)
    private var filterBar: some View {
        Group {
            if isIpad {
                // iPad: All filters in one row, spread equally
                HStack(spacing: 8) {
                    ForEach(AIBoardFilter.allCases) { filter in
                        filterButton(filter)
                    }
                }
                .padding(.horizontal, 12)
            } else {
                // iPhone: Two-row layout (3 + 3)
                VStack(spacing: 6) {
                    // Row 1: All, K, Outs
                    HStack(spacing: 6) {
                        filterButton(.all)
                        filterButton(.k)
                        filterButton(.outs)
                    }

                    // Row 2: HR, Hits, F5 ML
                    HStack(spacing: 6) {
                        filterButton(.hr)
                        filterButton(.hits)
                        filterButton(.f5ml)
                    }
                }
                .padding(.horizontal, 8)
            }
        }
        .frame(height: isIpad ? 54 : 108)
    }

    // MARK: - Filter button
    private func filterButton(_ filter: AIBoardFilter) -> some View {
        let stats = vm.hitStats(for: filter)
        let showCount = filter != .all && stats.total > 0
        let label = showCount
            ? "\(filter.rawValue) \(stats.hits)/\(stats.total)"
            : filter.rawValue

        return Button {
            vm.selectedFilter = filter
        } label: {
            Text(label)
                .scaledFont(size: 12,
                              weight: vm.selectedFilter == filter ? .bold : .medium,
                              design: .monospaced)
                .foregroundColor(vm.selectedFilter == filter ? .brandBackground : .brandTextMuted)
                .padding(.horizontal, 12)
                .padding(.vertical, isIpad ? 10 : 8)
                .frame(maxWidth: .infinity)
                .background(vm.selectedFilter == filter ? Color.brandGreen : Color.clear)
                .cornerRadius(6)
        }
    }

    // MARK: - Edge list
    private var edgeList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                // Header info
                if !vm.generatedAtLabel.isEmpty {
                    HStack {
                        Text("AI-scored picks · snapshot \(vm.generatedAtLabel)")
                            .scaledFont(size: 10, design: .monospaced)
                            .foregroundColor(.brandTextDim)
                        Spacer()
                        // Hit/miss record
                        if vm.hitCount + vm.missCount > 0 {
                            Text("\(vm.hitCount)/\(vm.hitCount + vm.missCount) hit")
                                .scaledFont(size: 10, weight: .bold, design: .monospaced)
                                .foregroundColor(.brandGreen)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                }

                let candidates = vm.filteredEdges

                if candidates.isEmpty && !vm.isLoading {
                    emptyState
                } else {
                    ForEach(Array(candidates.enumerated()), id: \.element.id) { index, edge in
                        AIBoardEdgeCardView(rank: index + 1, edge: edge)
                            .environmentObject(picksVM)
                            .padding(.horizontal, 16)
                    }
                }

                Spacer(minLength: 20)
            }
        }
        .refreshable { await vm.load() }
    }

    // MARK: - Empty state
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .scaledFont(size: 32)
                .foregroundColor(.brandTextDim)
                .padding(.top, 40)
            Text("No AI edges today")
                .scaledFont(size: 13, design: .monospaced)
                .foregroundColor(.brandTextMuted)
            Text("Snapshot runs at 10 AM HI daily")
                .scaledFont(size: 11, design: .monospaced)
                .foregroundColor(.brandTextDim)
        }
    }

    // MARK: - Loading / Error
    private var loadingView: some View {
        VStack(spacing: 12) {
            Spacer()
            ProgressView().tint(.brandGreen).scaleEffect(1.2)
            Text("Loading AI board…")
                .scaledFont(size: 13, design: .monospaced)
                .foregroundColor(.brandTextMuted)
            Spacer()
        }
    }

    private func errorView(_ msg: String) -> some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .scaledFont(size: 32)
                .foregroundColor(.brandAmber)
            Text(msg)
                .scaledFont(size: 12, design: .monospaced)
                .foregroundColor(.brandTextMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Retry") { Task { await vm.load() } }
                .scaledFont(size: 13, weight: .semibold, design: .monospaced)
                .foregroundColor(.brandGreen)
            Spacer()
        }
    }

    // MARK: - Toolbar
    private var titleToolbar: some ToolbarContent {
        Group {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .scaledFont(size: 14)
                        .foregroundColor(.brandPurple)
                    Text("AI Board")
                        .scaledFont(size: 17, weight: .bold, design: .monospaced)
                        .foregroundColor(.brandText)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                let total = vm.hitCount + vm.missCount
                if total > 0 {
                    Text("\(vm.hitCount)/\(total) hit")
                        .scaledFont(size: 11, weight: .bold, design: .monospaced)
                        .foregroundColor(.brandGreen)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.brandGreen.opacity(0.12))
                        .cornerRadius(5)
                }
            }
        }
    }
}
