import SwiftUI

struct PredictView: View {
    @StateObject private var vm = PredictViewModel()
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
        .task { await vm.load() }
        .colorScheme(.dark)
    }

    // MARK: - Pick list
    private var pickList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 10) {
                header

                let picks = vm.predictPicks
                if picks.isEmpty && !vm.isLoading {
                    emptyState
                } else {
                    ForEach(picks) { edge in
                        PredictCardView(edge: edge)
                            .environmentObject(picksVM)
                            .padding(.horizontal, 16)
                    }
                }

                Spacer(minLength: 20)
            }
        }
        .refreshable { await vm.load() }
    }

    // MARK: - Header
    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text("⚡ PREDICT")
                    .scaledFont(size: 13, weight: .bold, design: .monospaced)
                    .foregroundColor(.brandAmber)
                    .kerning(1)
                Spacer()
                Text("\(vm.predictPicks.count) picks")
                    .scaledFont(size: 10, design: .monospaced)
                    .foregroundColor(.brandTextDim)
            }

            Text("Edge plays — model probability exceeds book implied · sorted by edge")
                .scaledFont(size: 11, design: .monospaced)
                .foregroundColor(.brandTextMuted)
                .fixedSize(horizontal: false, vertical: true)

            Text("⊘ LOCKED · IN PLAY / FINAL")
                .scaledFont(size: 9, weight: .bold, design: .monospaced)
                .foregroundColor(.brandPurple)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.brandPurple.opacity(0.12))
                .cornerRadius(4)
                .kerning(0.5)

            if !vm.generatedAtLabel.isEmpty {
                Text("Snapshot \(vm.generatedAtLabel)")
                    .scaledFont(size: 10, design: .monospaced)
                    .foregroundColor(.brandTextDim)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    // MARK: - Empty state
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "bolt.fill")
                .scaledFont(size: 32)
                .foregroundColor(.brandTextDim)
                .padding(.top, 40)
            Text("No edge plays today")
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
            Text("Loading edge plays…")
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
        ToolbarItem(placement: .principal) {
            HStack(spacing: 6) {
                Image(systemName: "bolt.fill")
                    .scaledFont(size: 14)
                    .foregroundColor(.brandAmber)
                Text("Predict")
                    .scaledFont(size: 17, weight: .bold, design: .monospaced)
                    .foregroundColor(.brandText)
            }
        }
    }
}
