import SwiftUI

// MARK: - Slate skeleton card
struct SlateSkeletonCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Teams + status row
            HStack {
                bar(w: 52, h: 24)
                Spacer()
                bar(w: 44, h: 16)
                Spacer()
                bar(w: 52, h: 24)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            Divider().background(Color.brandBorder)

            // Venue + pitchers
            VStack(alignment: .leading, spacing: 6) {
                bar(w: 160, h: 11)
                bar(w: 120, h: 11)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider().background(Color.brandBorder)

            // Odds row
            HStack(spacing: 10) {
                bar(w: 70, h: 11)
                bar(w: 90, h: 11)
                Spacer()
                bar(w: 40, h: 11)
                bar(w: 56, h: 18).cornerRadius(4)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(Color.brandSurface)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.brandBorder, lineWidth: 1))
    }

    private func bar(w: CGFloat, h: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: h / 3)
            .fill(Color.brandSurface2)
            .frame(width: w, height: h)
            .shimmering()
    }
}

// MARK: - Board skeleton card
struct BoardSkeletonCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Rank + score + SIM
            HStack(spacing: 10) {
                bar(w: 16, h: 11)
                circle(32)
                bar(w: 50, h: 11)
                Spacer()
                bar(w: 44, h: 16).cornerRadius(4)
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)

            // Name + market + team
            HStack(spacing: 6) {
                bar(w: 140, h: 14)
                bar(w: 32, h: 18).cornerRadius(4)
                bar(w: 28, h: 11)
            }
            .padding(.horizontal, 14)
            .padding(.top, 8)

            // Game label
            bar(w: 100, h: 11)
                .padding(.horizontal, 14)
                .padding(.top, 4)

            // Stats row
            HStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { _ in statPill() }
            }
            .padding(.horizontal, 14)
            .padding(.top, 8)

            Divider().background(Color.brandBorder).padding(.top, 10)

            // Lean + line
            HStack {
                bar(w: 44, h: 12)
                bar(w: 30, h: 12)
                Spacer()
                bar(w: 60, h: 11)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .background(Color.brandSurface)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.brandBorder, lineWidth: 1))
    }

    private func statPill() -> some View {
        VStack(spacing: 3) {
            bar(w: 30, h: 12)
            bar(w: 24, h: 9)
        }
    }

    private func bar(w: CGFloat, h: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: h / 3)
            .fill(Color.brandSurface2)
            .frame(width: w, height: h)
            .shimmering()
    }

    private func circle(_ size: CGFloat) -> some View {
        Circle()
            .fill(Color.brandSurface2)
            .frame(width: size, height: size)
            .shimmering()
    }
}

// MARK: - Pick skeleton card
struct PickSkeletonCard: View {
    var body: some View {
        HStack(spacing: 12) {
            // Market badge
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.brandSurface2)
                .frame(width: 44, height: 22)
                .shimmering()

            VStack(alignment: .leading, spacing: 5) {
                bar(w: 120, h: 13)
                bar(w: 160, h: 10)
                bar(w: 60, h: 10)
            }

            Spacer()

            bar(w: 44, h: 18).cornerRadius(4)
        }
        .padding(14)
        .background(Color.brandSurface)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.brandBorder, lineWidth: 1))
    }

    private func bar(w: CGFloat, h: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: h / 3)
            .fill(Color.brandSurface2)
            .frame(width: w, height: h)
            .shimmering()
    }
}

// MARK: - Convenience stacks
struct SlateSkeletonList: View {
    var count = 5
    var body: some View {
        LazyVStack(spacing: 10) {
            ForEach(0..<count, id: \.self) { _ in
                SlateSkeletonCard().padding(.horizontal, 16)
            }
        }
        .padding(.top, 8)
    }
}

struct BoardSkeletonList: View {
    var count = 4
    var body: some View {
        LazyVStack(spacing: 10) {
            ForEach(0..<count, id: \.self) { _ in
                BoardSkeletonCard().padding(.horizontal, 16)
            }
        }
        .padding(.top, 10)
    }
}

struct PicksSkeletonList: View {
    var count = 4
    var body: some View {
        LazyVStack(spacing: 8) {
            ForEach(0..<count, id: \.self) { _ in
                PickSkeletonCard().padding(.horizontal, 16)
            }
        }
    }
}
