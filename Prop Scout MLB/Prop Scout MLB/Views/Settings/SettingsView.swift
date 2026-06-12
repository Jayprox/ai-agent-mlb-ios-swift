import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var showSignOutConfirm = false

    private let books = ["DK", "FD", "CZR", "MGM", "BOV"]
    private let bookNames = [
        "DK":  "DraftKings",
        "FD":  "FanDuel",
        "CZR": "Caesars",
        "MGM": "BetMGM",
        "BOV": "Bovada"
    ]

    var body: some View {
        NavigationView {
            ZStack {
                Color.brandBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {

                        // MARK: - User card
                        userCard

                        // MARK: - Preferred book
                        sectionCard(title: "PREFERRED BOOK") {
                            VStack(spacing: 0) {
                                ForEach(books, id: \.self) { book in
                                    Button {
                                        HapticManager.light()
                                        Task { await auth.updatePreferredBook(book) }
                                    } label: {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(bookNames[book] ?? book)
                                                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                                                    .foregroundColor(.brandText)
                                                Text(book)
                                                    .font(.system(size: 11, design: .monospaced))
                                                    .foregroundColor(.brandTextDim)
                                            }
                                            Spacer()
                                            if auth.preferredBook == book {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.brandGreen)
                                                    .font(.system(size: 18))
                                            } else {
                                                Circle()
                                                    .stroke(Color.brandBorder2, lineWidth: 1.5)
                                                    .frame(width: 20, height: 20)
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                    }

                                    if book != books.last {
                                        Divider()
                                            .background(Color.brandBorder)
                                            .padding(.leading, 16)
                                    }
                                }
                            }
                        }

                        // MARK: - App info
                        sectionCard(title: "APP") {
                            infoRow(label: "Version", value: "1.0.0")
                            Divider().background(Color.brandBorder).padding(.leading, 16)
                            infoRow(label: "Backend", value: "Railway ✓")
                            Divider().background(Color.brandBorder).padding(.leading, 16)
                            infoRow(label: "Board", value: "Refreshes 10 AM HI")
                        }

                        // MARK: - Legal
                        sectionCard(title: "LEGAL") {
                            VStack(spacing: 0) {
                                navRow(label: "Privacy Policy") {
                                    LegalDocumentView.privacyPolicy
                                }
                                Divider().background(Color.brandBorder).padding(.leading, 16)
                                navRow(label: "Terms of Service") {
                                    LegalDocumentView.termsOfService
                                }
                            }
                        }

                        // MARK: - Disclaimer
                        Text("Prop Scout MLB is an informational research tool. Picks, odds, and AI-generated analysis are for entertainment purposes only and do not constitute gambling, financial, or betting advice. Must be 21+ to use sportsbook-related features. If you or someone you know has a gambling problem, call 1-800-GAMBLER.")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.brandTextDim)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .padding(.top, 4)

                        // MARK: - Sign out
                        Button {
                            showSignOutConfirm = true
                        } label: {
                            Text("Sign Out")
                                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                .foregroundColor(.brandRed)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(Color.brandRed.opacity(0.1))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.brandRed.opacity(0.3), lineWidth: 1)
                                )
                        }
                        .padding(.horizontal, 16)
                        .confirmationDialog("Sign out of Prop Scout?", isPresented: $showSignOutConfirm, titleVisibility: .visible) {
                            Button("Sign Out", role: .destructive) { auth.signOut() }
                            Button("Cancel", role: .cancel) {}
                        }

                        Text("⚡ Full live mode — weather · odds · MLB stats · Savant")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.brandTextDim)
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 8)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.brandTextMuted)
                        Text("Settings")
                            .font(.system(size: 17, weight: .bold, design: .monospaced))
                            .foregroundColor(.brandText)
                    }
                }
            }
        }
        .colorScheme(.dark)
    }

    // MARK: - User card
    private var userCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.brandGreen.opacity(0.15))
                    .frame(width: 48, height: 48)
                Text(auth.username.prefix(1).uppercased())
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundColor(.brandGreen)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(auth.username.isEmpty ? "leadoffkaiba" : auth.username)
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundColor(.brandText)
                Text("Prop Scout MLB")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.brandTextDim)
            }
            Spacer()
        }
        .padding(16)
        .background(Color.brandSurface)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.brandBorder, lineWidth: 1))
        .padding(.horizontal, 16)
    }

    // MARK: - Section card
    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.brandTextDim)
                .kerning(1.5)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)

            VStack(spacing: 0) {
                content()
            }
            .background(Color.brandSurface)
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.brandBorder, lineWidth: 1))
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Nav row
    private func navRow<Destination: View>(label: String, @ViewBuilder destination: () -> Destination) -> some View {
        NavigationLink(destination: destination()) {
            HStack {
                Text(label)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.brandText)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11))
                    .foregroundColor(.brandTextDim)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
    }

    // MARK: - Info row
    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(.brandTextMuted)
            Spacer()
            Text(value)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(.brandTextDim)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
