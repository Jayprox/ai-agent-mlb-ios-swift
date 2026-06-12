import SwiftUI

struct ScoutView: View {
    @StateObject private var vm = ScoutViewModel()
    @EnvironmentObject var picksVM: PicksViewModel

    var body: some View {
        NavigationView {
            ZStack {
                Color.brandBackground.ignoresSafeArea()

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 14) {
                        configCard

                        if vm.hasBuilt {
                            slateSection
                        } else {
                            helperText
                        }

                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
                .refreshable { await vm.load() }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { titleToolbar }
        }
        .task { await vm.load() }
        .colorScheme(.dark)
    }

    // MARK: - Config card
    private var configCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("🎯 THE SCOUT")
                    .scaledFont(size: 13, weight: .bold, design: .monospaced)
                    .foregroundColor(.brandText)
                    .kerning(1)
                Text("Builds a bankroll-aware slate from the strongest live edges, then adds short bettor-style reasoning for each play.")
                    .scaledFont(size: 11, design: .monospaced)
                    .foregroundColor(.brandTextMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Daily goal
            VStack(alignment: .leading, spacing: 6) {
                Text("DAILY GOAL")
                    .scaledFont(size: 9, weight: .bold, design: .monospaced)
                    .foregroundColor(.brandTextDim)
                    .kerning(1)
                HStack(spacing: 8) {
                    ForEach(ScoutViewModel.dailyGoalOptions, id: \.self) { value in
                        pillButton(
                            label: "$\(value)",
                            isSelected: vm.dailyGoal == value,
                            color: .brandGreen
                        ) {
                            vm.dailyGoal = value
                        }
                    }
                }
            }

            // Unit size
            VStack(alignment: .leading, spacing: 6) {
                Text("UNIT SIZE")
                    .scaledFont(size: 9, weight: .bold, design: .monospaced)
                    .foregroundColor(.brandTextDim)
                    .kerning(1)
                HStack(spacing: 8) {
                    ForEach(ScoutViewModel.unitSizeOptions, id: \.self) { value in
                        pillButton(
                            label: "$\(value)",
                            isSelected: vm.unitSize == value,
                            color: .brandPurple
                        ) {
                            vm.unitSize = value
                        }
                    }
                }
            }

            // Stat grid
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                statBox(label: "TARGET", value: "$\(vm.target)")
                statBox(label: "UNITS NEEDED", value: "\(vm.unitsNeeded)")
                statBox(label: "RISK ESTIMATE", value: "$\(vm.riskEstimate)")
                statBox(label: "ASSUMED HIT RATE", value: vm.assumedHitRateDisplay)
            }

            // Action buttons
            HStack(spacing: 10) {
                Button {
                    HapticManager.light()
                    vm.buildSlate()
                } label: {
                    Text("Build Scout Slate")
                        .scaledFont(size: 14, weight: .bold, design: .monospaced)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.brandGreen)
                        .cornerRadius(8)
                }

                Button {
                    HapticManager.light()
                    vm.regenerate()
                } label: {
                    Text("Regenerate")
                        .scaledFont(size: 14, weight: .semibold, design: .monospaced)
                        .foregroundColor(.brandText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.brandSurface2)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.brandBorder, lineWidth: 1))
                }
                .disabled(!vm.hasBuilt)
                .opacity(vm.hasBuilt ? 1 : 0.5)
            }
        }
        .padding(14)
        .background(Color.brandSurface)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.brandBorder, lineWidth: 1))
    }

    // MARK: - Helper text
    private var helperText: some View {
        Text("Set your goal and unit size, then let Scout build a slate from the strongest -110-style edge plays on the board.")
            .scaledFont(size: 11, design: .monospaced)
            .foregroundColor(.brandTextDim)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.top, 30)
            .padding(.horizontal, 20)
    }

    // MARK: - Slate section
    private var slateSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("SCOUT SLATE")
                    .scaledFont(size: 10, weight: .bold, design: .monospaced)
                    .foregroundColor(.brandTextDim)
                    .kerning(1)
                Spacer()
                Text("\(vm.slate.count) plays · \(vm.slate.count)u")
                    .scaledFont(size: 10, design: .monospaced)
                    .foregroundColor(.brandTextDim)
            }

            if vm.slate.isEmpty {
                Text("No live edges available right now.")
                    .scaledFont(size: 12, design: .monospaced)
                    .foregroundColor(.brandTextMuted)
                    .padding(.top, 10)
            } else {
                ForEach(vm.slate) { edge in
                    scoutPickCard(edge)
                }
            }
        }
    }

    private func scoutPickCard(_ edge: AIBoardEdge) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                MarketBadge(market: edge.market ?? "")
                Text(edge.displayName)
                    .scaledFont(size: 13, weight: .bold, design: .monospaced)
                    .foregroundColor(.brandText)
                Spacer()
                Text("\(edge.aiScore)")
                    .scaledFont(size: 11, weight: .bold, design: .monospaced)
                    .foregroundColor(edge.aiScoreColor)
            }
            Text(edge.displayGameLabel)
                .scaledFont(size: 10, design: .monospaced)
                .foregroundColor(.brandTextDim)

            Text(edge.scoutReasoning)
                .scaledFont(size: 11, design: .monospaced)
                .italic()
                .foregroundColor(.brandTextMuted)
                .lineSpacing(3)
        }
        .padding(12)
        .background(Color.brandSurface)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.brandBorder, lineWidth: 1))
    }

    // MARK: - Reusable pieces

    private func pillButton(label: String, isSelected: Bool, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .scaledFont(size: 13, weight: isSelected ? .bold : .medium, design: .monospaced)
                .foregroundColor(isSelected ? .black : .brandTextMuted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(isSelected ? color : Color.brandSurface2)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? color : Color.brandBorder, lineWidth: 1)
                )
        }
    }

    private func statBox(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .scaledFont(size: 9, weight: .bold, design: .monospaced)
                .foregroundColor(.brandTextDim)
                .kerning(1)
            Text(value)
                .scaledFont(size: 18, weight: .bold, design: .monospaced)
                .foregroundColor(.brandText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.brandSurface2)
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.brandBorder, lineWidth: 1))
    }

    // MARK: - Toolbar
    private var titleToolbar: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            HStack(spacing: 6) {
                Image(systemName: "scope")
                    .scaledFont(size: 14)
                    .foregroundColor(.brandGreen)
                Text("Scout")
                    .scaledFont(size: 17, weight: .bold, design: .monospaced)
                    .foregroundColor(.brandText)
            }
        }
    }
}
