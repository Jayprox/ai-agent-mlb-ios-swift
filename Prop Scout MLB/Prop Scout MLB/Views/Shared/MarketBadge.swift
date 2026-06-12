import SwiftUI

struct MarketBadge: View {
    let market: String

    private var meta: (label: String, color: Color) {
        switch market.lowercased() {
        case "hr":      return ("HR",     .marketHR)
        case "hits":    return ("Hits",   .marketHits)
        case "k":       return ("K",      .marketK)
        case "outs":    return ("Outs",   .marketOuts)
        case "ml":      return ("ML",     .marketML)
        case "spread":  return ("Spread", .marketSpread)
        case "total":   return ("O/U",    .marketTotal)
        case "nrfi":    return ("NRFI",   .marketNRFI)
        case "f5ml":    return ("F5 ML",  .marketF5ML)
        case "f5spread":return ("F5 RL",  .marketF5RL)
        default:        return (market.uppercased(), .brandTextMuted)
        }
    }

    var body: some View {
        Text(meta.label)
            .scaledFont(size: 10, weight: .bold, design: .monospaced)
            .foregroundColor(meta.color)
            .lineLimit(1)
            .fixedSize()
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(meta.color.opacity(0.15))
            .cornerRadius(4)
    }
}

struct NRFILeanBadge: View {
    let lean: String
    let confidence: Int?
    var reason: String? = nil

    private var isNRFI: Bool { lean.uppercased() == "NRFI" }
    private var color: Color { isNRFI ? .marketNRFI : .brandAmber }

    var body: some View {
        HStack(spacing: 3) {
            Text(lean.uppercased())
                .scaledFont(size: 10, weight: .bold, design: .monospaced)
            // Prefer reason over confidence — reason is more informative
            if let r = reason {
                Text("(\(r))")
                    .scaledFont(size: 10, design: .monospaced)
            } else if let conf = confidence {
                Text("\(conf)%")
                    .scaledFont(size: 10, weight: .semibold, design: .monospaced)
            }
        }
        .foregroundColor(color)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(color.opacity(0.12))
        .cornerRadius(4)
    }
}
