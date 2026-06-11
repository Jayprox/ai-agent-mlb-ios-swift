import SwiftUI

struct LogPickSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var vm: PicksViewModel

    // Pre-fill support (from board card)
    var prefill: LogPickPrefill? = nil

    @State private var playerName: String = ""
    @State private var playerIdInput: String = ""
    @State private var market: String = "k"
    @State private var side: String = "OVER"
    @State private var bookLine: String = ""
    @State private var odds: String = ""
    @State private var units: String = "1"
    @State private var gameLabel: String = ""
    @State private var isLogging = false
    @State private var errorMessage: String? = nil

    private let markets = ["hr","hits","k","outs","ml","spread","total","nrfi","f5ml","f5spread"]
    private let sides = ["OVER","UNDER","HOME","AWAY","NRFI","YRFI"]

    var body: some View {
        ZStack {
            Color.brandBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Handle
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.brandBorder2)
                    .frame(width: 36, height: 4)
                    .padding(.top, 12)
                    .padding(.bottom, 20)

                ScrollView {
                    VStack(spacing: 16) {
                        Text("LOG PICK")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(.brandTextDim)
                            .kerning(2)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        // Player / Game name + ID row
                        HStack(spacing: 12) {
                            formField(label: "PLAYER / GAME") {
                                TextField("e.g. Jacob deGrom", text: $playerName)
                                    .styledInput()
                            }
                            formField(label: "PLAYER ID") {
                                TextField("MLB ID", text: $playerIdInput)
                                    .keyboardType(.numberPad)
                                    .styledInput()
                                    .frame(width: 90)
                            }
                        }

                        // Market + Side row
                        HStack(spacing: 12) {
                            formField(label: "MARKET") {
                                Picker("", selection: $market) {
                                    ForEach(markets, id: \.self) { m in
                                        Text(m.uppercased()).tag(m)
                                    }
                                }
                                .pickerStyle(.menu)
                                .accentColor(.brandGreen)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(Color.brandSurface2)
                                .cornerRadius(8)
                            }

                            formField(label: "SIDE") {
                                Picker("", selection: $side) {
                                    ForEach(sides, id: \.self) { s in
                                        Text(s).tag(s)
                                    }
                                }
                                .pickerStyle(.menu)
                                .accentColor(.brandGreen)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(Color.brandSurface2)
                                .cornerRadius(8)
                            }
                        }

                        // Line + Odds row
                        HStack(spacing: 12) {
                            formField(label: "BOOK LINE") {
                                TextField("e.g. 4.5", text: $bookLine)
                                    .keyboardType(.decimalPad)
                                    .styledInput()
                            }
                            formField(label: "ODDS") {
                                TextField("e.g. -130", text: $odds)
                                    .keyboardType(.numbersAndPunctuation)
                                    .styledInput()
                            }
                        }

                        // Units + Game label row
                        HStack(spacing: 12) {
                            formField(label: "UNITS") {
                                TextField("1", text: $units)
                                    .keyboardType(.decimalPad)
                                    .styledInput()
                            }
                            formField(label: "GAME") {
                                TextField("e.g. NYY @ PHI", text: $gameLabel)
                                    .styledInput()
                            }
                        }

                        // Error
                        if let err = errorMessage {
                            Text(err)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.brandRed)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        // Submit button
                        Button(action: submit) {
                            ZStack {
                                if isLogging {
                                    ProgressView().tint(.brandBackground)
                                } else {
                                    Text("LOG PICK")
                                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                                        .foregroundColor(.brandBackground)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(canSubmit ? Color.brandGreen : Color.brandTextDim)
                            .cornerRadius(8)
                        }
                        .disabled(!canSubmit || isLogging)
                    }
                    .padding(20)
                }
            }
        }
        .colorScheme(.dark)
        .onAppear { applyPrefill() }
    }

    // MARK: - Helpers
    private var canSubmit: Bool {
        !playerName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !bookLine.isEmpty &&
        Double(bookLine) != nil
    }

    private func applyPrefill() {
        guard let p = prefill else { return }
        playerName    = p.playerName
        market        = p.market
        side          = p.side
        bookLine      = p.bookLine.map { String($0) } ?? ""
        odds          = p.odds ?? ""
        gameLabel     = p.gameLabel
        playerIdInput = p.playerId.map { String($0) } ?? ""
    }

    private func submit() {
        guard let line = Double(bookLine),
              let u = Double(units.isEmpty ? "1" : units) else { return }
        isLogging = true
        errorMessage = nil

        let today = DateFormatter()
        today.dateFormat = "yyyy-MM-dd"
        today.timeZone = TimeZone(identifier: "Pacific/Honolulu")

        let req = LogPickRequest(
            playerId: Int(playerIdInput),
            playerName: playerName.trimmingCharacters(in: .whitespaces),
            market: market,
            side: side,
            bookLine: line,
            odds: odds.isEmpty ? nil : odds,
            units: u,
            slateDate: today.string(from: Date()),
            gameLabel: gameLabel.trimmingCharacters(in: .whitespaces),
            source: "ios"
        )

        Task {
            do {
                _ = try await vm.logPick(req)
                await MainActor.run {
                    HapticManager.success()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    HapticManager.error()
                    errorMessage = error.localizedDescription
                    isLogging = false
                }
            }
        }
    }
}

// MARK: - Prefill model
struct LogPickPrefill {
    let playerName: String
    let market: String
    let side: String
    let bookLine: Double?
    let odds: String?
    let gameLabel: String
    var playerId: Int? = nil
}

// MARK: - Form helpers
private func formField<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
    VStack(alignment: .leading, spacing: 6) {
        Text(label)
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .foregroundColor(.brandTextDim)
            .kerning(1.2)
        content()
    }
}

private extension View {
    func styledInput() -> some View {
        self
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.brandSurface2)
            .foregroundColor(.brandText)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.brandBorder, lineWidth: 1))
    }
}
