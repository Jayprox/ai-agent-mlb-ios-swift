import SwiftUI

struct MoreView: View {
    @EnvironmentObject var picksVM: PicksViewModel
    @EnvironmentObject var router: TabRouter

    var body: some View {
        NavigationView {
            ZStack {
                Color.brandBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        // Menu items
                        moreMenuItem(
                            label: "Leaderboard",
                            icon: "chart.bar.fill",
                            color: .brandGreen,
                            destination: { LeaderboardView() }
                        )

                        moreMenuItem(
                            label: "Predict",
                            icon: "bolt.fill",
                            color: .brandAmber,
                            destination: { PredictView().environmentObject(picksVM) }
                        )

                        moreMenuItem(
                            label: "Scout",
                            icon: "scope",
                            color: .brandCyan,
                            destination: { ScoutView().environmentObject(picksVM) }
                        )

                        moreMenuItem(
                            label: "Chat",
                            icon: "bubble.left.and.bubble.right.fill",
                            color: .brandGreen,
                            destination: { ChatView() }
                        )

                        moreMenuItem(
                            label: "Picks",
                            icon: "note.text",
                            color: .brandGreen,
                            destination: { PicksView().environmentObject(picksVM) }
                        )

                        moreMenuItem(
                            label: "Settings",
                            icon: "gearshape.fill",
                            color: .brandTextMuted,
                            destination: { SettingsView() }
                        )
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("More")
                        .scaledFont(size: 17, weight: .bold, design: .monospaced)
                        .foregroundColor(.brandText)
                }
            }
        }
        .navigationViewStyle(.stack)
        .colorScheme(.dark)
    }

    private func moreMenuItem<Destination: View>(
        label: String,
        icon: String,
        color: Color,
        @ViewBuilder destination: @escaping () -> Destination
    ) -> some View {
        VStack(spacing: 0) {
            NavigationLink(destination: destination()) {
                HStack(spacing: 16) {
                    Image(systemName: icon)
                        .scaledFont(size: 18)
                        .foregroundColor(color)
                        .frame(width: 28, alignment: .center)

                    Text(label)
                        .scaledFont(size: 16, design: .monospaced)
                        .foregroundColor(.brandText)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .scaledFont(size: 12)
                        .foregroundColor(.brandTextDim)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .contentShape(Rectangle())
            }

            Divider()
                .background(Color.brandBorder.opacity(0.5))
                .padding(.leading, 60)
        }
    }
}

#Preview {
    MoreView()
}
