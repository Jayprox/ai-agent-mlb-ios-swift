import SwiftUI

struct ModelPicksView: View {
    @StateObject private var vm = ModelPicksViewModel()
    @EnvironmentObject var picksVM: PicksViewModel

    var body: some View {
        NavigationView {
            ZStack {
                Color.brandBackground.ignoresSafeArea()

                if vm.isLoading && vm.edges.isEmpty {
                    loadingView
                } else if let error = vm.errorMessage, vm.edges.isEmpty {
                    errorView(error)
                } else {
                    pickList
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

    // MARK: - Pick list
    private var pickList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 10) {
                header

                let picks = vm.modelPicks
                if picks.isEmpty && !vm.isLoading {
                    emptyState
                } else {
                    ForEach(ModelConfidenceTier.allCases, id: \.self) { tier in
                        let tierPicks = vm.picks(for: tier)
                        if !tierPicks.isEmpty {
                            confidenceSection(tier, picks: tierPicks)
                        }
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
            HStack {
                Text("— MODEL PICKS")
                    .scaledFont(size: 10, weight: .bold, design: .monospaced)
                    .foregroundColor(.brandTextDim)
                    .kerning(1)

                Text("ALGORITHMIC")
                    .scaledFont(size: 8, weight: .bold, design: .monospaced)
                    .foregroundColor(.brandCyan)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.brandCyan.opacity(0.12))
                    .cornerRadius(4)
                    .kerning(0.5)

                Spacer()

                let stats = vm.hitStats
                if stats.total > 0 {
                    Text("\(stats.hits)/\(stats.total) hit")
                        .scaledFont(size: 10, weight: .bold, design: .monospaced)
                        .foregroundColor(.brandGreen)
                }

                Text("\(vm.modelPicks.count) picks")
                    .scaledFont(size: 10, design: .monospaced)
                    .foregroundColor(.brandTextDim)
            }

            if !vm.generatedAtLabel.isEmpty {
                Text("Snapshot \(vm.generatedAtLabel)")
                    .scaledFont(size: 10, design: .monospaced)
                    .foregroundColor(.brandTextDim)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    // MARK: - Confidence section
    private func confidenceSection(_ tier: ModelConfidenceTier, picks: [AIBoardEdge]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(tier.rawValue)
                .scaledFont(size: 10, weight: .bold, design: .monospaced)
                .foregroundColor(tierColor(tier))
                .kerning(1)
                .padding(.horizontal, 16)
                .padding(.top, 6)

            ForEach(picks) { edge in
                ModelPickCardView(edge: edge)
                    .environmentObject(picksVM)
                    .padding(.horizontal, 16)
            }
        }
    }

    private func tierColor(_ tier: ModelConfidenceTier) -> Color {
        switch tier {
        case .high:   return .brandGreen
        case .medium: return .brandAmber
        case .low:    return .brandTextDim
        }
    }

    // MARK: - Empty state
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "cpu")
                .scaledFont(size: 32)
                .foregroundColor(.brandTextDim)
                .padding(.top, 40)
            Text("No model picks today")
                .scaledFont(size: 13, design: .monospaced)
                .foregroundColor(.brandTextMuted)
            Text("Snapshot runs at 10 AM HI daily")
                .scaledFont(size: 11, design: .monospaced)
                .foregroundColor(.brandTextDim)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Loading / Error
    private var loadingView: some View {
        VStack(spacing: 12) {
            Spacer()
            ProgressView().tint(.brandGreen).scaleEffect(1.2)
            Text("Loading model picks…")
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
                    Image(systemName: "cpu")
                        .scaledFont(size: 14)
                        .foregroundColor(.brandCyan)
                    Text("Model")
                        .scaledFont(size: 17, weight: .bold, design: .monospaced)
                        .foregroundColor(.brandText)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                let stats = vm.hitStats
                if stats.total > 0 {
                    Text("\(stats.hits)/\(stats.total) hit")
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
