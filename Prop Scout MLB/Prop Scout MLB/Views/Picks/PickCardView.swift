import SwiftUI

struct PickCardView: View {
    let pick: Pick
    let onVoid: () -> Void
    let onGrade: (Bool) -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Market badge — fixed size to prevent wrapping on longer labels (e.g. "Spread")
            MarketBadge(market: pick.market)
                .fixedSize()

            // Main content
            VStack(alignment: .leading, spacing: 3) {
                // Player / game name
                Text(pick.playerName ?? pick.gameLabel ?? "—")
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundColor(.brandText)

                // Side + line · game · units
                HStack(spacing: 4) {
                    Text(pick.lineDisplay)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.brandTextMuted)
                    if let game = pick.gameLabel, pick.playerName != nil {
                        Text("·")
                            .foregroundColor(.brandTextDim)
                        Text(game)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.brandTextDim)
                    }
                    if let units = pick.units {
                        Text("·")
                            .foregroundColor(.brandTextDim)
                        Text("\(units == units.rounded() ? "\(Int(units))" : String(format: "%.1f", units))u")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.brandTextDim)
                    }
                }

                // Odds + P&L
                HStack(spacing: 8) {
                    if let odds = pick.oddsDisplay {
                        Text(odds)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.brandTextDim)
                    }
                    if !pick.pnlDisplay.isEmpty {
                        Text(pick.pnlDisplay)
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundColor((pick.pnl ?? 0) >= 0 ? .brandGreen : .brandRed)
                    }
                }
            }

            Spacer()

            // Result badge + actions
            VStack(alignment: .trailing, spacing: 6) {
                resultBadge

                // Actions for pending picks
                if pick.isPending {
                    HStack(spacing: 8) {
                        Button {
                            HapticManager.success()
                            onGrade(true)
                        } label: {
                            Text("✓")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.brandGreen)
                                .frame(width: 28, height: 28)
                                .background(Color.brandGreen.opacity(0.12))
                                .cornerRadius(6)
                        }
                        Button {
                            HapticManager.error()
                            onGrade(false)
                        } label: {
                            Text("✗")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.brandRed)
                                .frame(width: 28, height: 28)
                                .background(Color.brandRed.opacity(0.12))
                                .cornerRadius(6)
                        }
                        Button {
                            HapticManager.warning()
                            onVoid()
                        } label: {
                            Text("void")
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundColor(.brandTextDim)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 4)
                                .background(Color.brandSurface2)
                                .cornerRadius(4)
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(Color.brandSurface)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(borderColor, lineWidth: 1)
        )
    }

    @ViewBuilder
    private var resultBadge: some View {
        if pick.isHit {
            badge("HIT", color: .brandGreen)
        } else if pick.isMiss {
            badge("MISS", color: .brandRed)
        } else if pick.isPPD {
            badge("PPD", color: .brandAmber)
        } else if pick.isScratch {
            badge("SCR", color: .brandAmber)
        } else if pick.isPush {
            badge("PUSH", color: .brandTextMuted)
        } else if pick.isPending {
            badge("PENDING", color: .brandTextDim)
        }
    }

    private func badge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .bold, design: .monospaced))
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(color.opacity(0.12))
            .cornerRadius(4)
    }

    private var borderColor: Color {
        if pick.isHit  { return .brandGreen.opacity(0.25) }
        if pick.isMiss { return .brandRed.opacity(0.2) }
        return .brandBorder
    }
}
