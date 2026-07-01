import SwiftUI

struct LeaderboardOptInSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var vm: LeaderboardViewModel
    @State private var username: String = ""
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    var body: some View {
        NavigationView {
            ZStack {
                Color.brandBackground.ignoresSafeArea()

                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "chart.bar.fill")
                            .scaledFont(size: 28)
                            .foregroundColor(.brandGreen)

                        Text("Join the Leaderboard")
                            .scaledFont(size: 18, weight: .bold, design: .monospaced)
                            .foregroundColor(.brandText)

                        Text("Show off your picks and compete with other users")
                            .scaledFont(size: 12, design: .monospaced)
                            .foregroundColor(.brandTextMuted)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 24)

                    // Requirements info
                    VStack(alignment: .leading, spacing: 10) {
                        infoRow(icon: "checkmark.circle.fill", text: "Minimum 10 graded picks required", color: .brandCyan)
                        infoRow(icon: "person.crop.circle.fill", text: "Choose a display name (max 32 characters)", color: .brandAmber)
                        infoRow(icon: "eye.fill", text: "Your stats will be publicly visible", color: .brandGreen)
                        infoRow(icon: "xmark.circle.fill", text: "You can opt out anytime", color: .brandTextDim)
                    }
                    .padding(16)
                    .background(Color.brandSurface)
                    .cornerRadius(10)
                    .padding(.horizontal, 16)

                    Spacer()

                    // Username input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Display Name")
                            .scaledFont(size: 12, weight: .bold, design: .monospaced)
                            .foregroundColor(.brandTextMuted)

                        TextField("", text: $username)
                            .scaledFont(size: 14, design: .monospaced)
                            .foregroundColor(.brandText)
                            .padding(12)
                            .background(Color.brandSurface)
                            .cornerRadius(8)
                            .submitLabel(.done)
                            .onSubmit {
                                Task {
                                    await submitOptIn()
                                }
                            }
                            .onChange(of: username) { newValue in
                                username = String(newValue.prefix(32))
                            }

                        if !username.isEmpty {
                            Text("\(username.count)/32")
                                .scaledFont(size: 10, design: .monospaced)
                                .foregroundColor(.brandTextDim)
                        }
                    }
                    .padding(.horizontal, 16)

                    // Error message
                    if showError && !errorMessage.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .scaledFont(size: 12)
                                .foregroundColor(.brandRed)

                            Text(errorMessage)
                                .scaledFont(size: 11, design: .monospaced)
                                .foregroundColor(.brandRed)
                                .lineLimit(2)

                            Spacer()
                        }
                        .padding(12)
                        .background(Color.brandRed.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal, 16)
                    }

                    Spacer()

                    // Action buttons
                    VStack(spacing: 10) {
                        Button {
                            Task {
                                await submitOptIn()
                            }
                        } label: {
                            if vm.isOptingIn {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.brandBackground)
                            } else {
                                Text("Join Leaderboard")
                                    .scaledFont(size: 14, weight: .semibold, design: .monospaced)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.brandGreen)
                        .foregroundColor(.brandBackground)
                        .cornerRadius(10)
                        .disabled(username.isEmpty || vm.isOptingIn)
                        .opacity(username.isEmpty || vm.isOptingIn ? 0.5 : 1.0)

                        Button {
                            dismiss()
                        } label: {
                            Text("Not Now")
                                .scaledFont(size: 14, weight: .semibold, design: .monospaced)
                                .foregroundColor(.brandTextMuted)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .scaledFont(size: 14)
                            .foregroundColor(.brandTextMuted)
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
        .colorScheme(.dark)
        .onAppear {
            if let defaultUsername = vm.userStats?.username {
                username = defaultUsername
            }
        }
    }

    private func infoRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .scaledFont(size: 14)
                .foregroundColor(color)
                .frame(width: 20)

            Text(text)
                .scaledFont(size: 12, design: .monospaced)
                .foregroundColor(.brandText)

            Spacer()
        }
    }

    private func submitOptIn() async {
        guard !username.isEmpty else { return }

        let success = await vm.optInToLeaderboard(username: username)
        if success {
            dismiss()
        } else if let error = vm.errorMessage {
            errorMessage = error
            showError = true
        }
    }
}

#Preview {
    LeaderboardOptInSheet(vm: LeaderboardViewModel())
}
