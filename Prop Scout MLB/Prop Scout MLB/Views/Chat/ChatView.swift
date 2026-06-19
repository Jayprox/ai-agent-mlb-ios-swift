import SwiftUI

struct ChatView: View {
    @StateObject private var vm = ChatViewModel()
    @State private var inputText = ""
    @FocusState private var inputFocused: Bool
    @State private var scrollProxy: ScrollViewProxy? = nil

    private let suggestions = [
        "Build me a 3-leg parlay",
        "Best K props tonight",
        "Best hits props tonight",
        "Top plays across all markets",
        "Any injury alerts?"
    ]

    var body: some View {
        NavigationView {
            ZStack {
                Color.brandBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Persona selector — always shown
                    personaBar

                    Divider().background(Color.brandBorder)

                    // Suggested prompts (shown when no messages)
                    if vm.messages.isEmpty {
                        emptyState
                    } else {
                        messageList
                    }

                    // Error banner
                    if let error = vm.errorMessage {
                        Text(error)
                            .scaledFont(size: 11, design: .monospaced)
                            .foregroundColor(.brandRed)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                    }

                    // Input bar
                    inputBar
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { titleToolbar }
        }
        .colorScheme(.dark)
    }

    // MARK: - Persona bar
    private var personaBar: some View {
        HStack(spacing: 0) {
            personaTab("Pro", value: "pro")
            personaTab("Lotto", value: "lotto")
        }
        .background(Color.brandSurface2)
        .cornerRadius(8)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func personaTab(_ label: String, value: String) -> some View {
        Button {
            if vm.persona != value {
                HapticManager.light()
                vm.persona = value
            }
        } label: {
            Text(label)
                .scaledFont(size: 12, weight: .semibold, design: .monospaced)
                .foregroundColor(vm.persona == value ? .brandBackground : .brandTextDim)
                .padding(.horizontal, 20)
                .padding(.vertical, 7)
                .background(
                    vm.persona == value ? Color.brandGreen : Color.clear
                )
                .cornerRadius(7)
                .animation(.easeInOut(duration: 0.15), value: vm.persona)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty state with suggestion chips
    private var emptyState: some View {
        ScrollView {
            VStack(spacing: 20) {
                Spacer(minLength: 20)

                Text(vm.persona == "lotto"
                     ? "Parlay builder — finds high-upside multi-leg combinations"
                     : "Smart slate assistant with injury, odds, props, and web context")
                    .scaledFont(size: 12, design: .monospaced)
                    .foregroundColor(.brandTextDim)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .animation(.easeInOut(duration: 0.2), value: vm.persona)

                ChipFlowView(
                    chips: suggestions,
                    disabled: vm.isAtLimit
                ) { prompt in
                    HapticManager.light()
                    inputText = prompt
                    Task { await sendMessage() }
                }
                .padding(.horizontal, 16)

                Spacer()

                Text("Ask about today's slate, top K props, line movement, injury impact, or a specific pitcher/game.")
                    .scaledFont(size: 12, design: .monospaced)
                    .foregroundColor(.brandTextDim)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Spacer(minLength: 20)
            }
        }
    }

    // MARK: - Message list
    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(vm.messages) { msg in
                        MessageBubble(message: msg)
                            .id(msg.id)
                    }
                    if vm.isSending {
                        TypingIndicator()
                            .id("typing")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .onAppear { scrollProxy = proxy }
            .onChange(of: vm.messages.count) { _ in scrollToBottom(proxy: proxy) }
            .onChange(of: vm.isSending) { _ in scrollToBottom(proxy: proxy) }
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.3)) {
            if vm.isSending {
                proxy.scrollTo("typing", anchor: .bottom)
            } else if let last = vm.messages.last {
                proxy.scrollTo(last.id, anchor: .bottom)
            }
        }
    }

    // MARK: - Input bar
    private var inputBar: some View {
        VStack(spacing: 0) {
            Divider().background(Color.brandBorder)
            HStack(spacing: 10) {
                TextField(
                    vm.isAtLimit ? "Daily limit reached" : "Ask Chalk That about today's slate...",
                    text: $inputText,
                    axis: .vertical
                )
                .lineLimit(1...4)
                .scaledFont(size: 13, design: .monospaced)
                .foregroundColor(.brandText)
                .focused($inputFocused)
                .disabled(vm.isAtLimit)
                .submitLabel(.send)
                .onSubmit { Task { await sendMessage() } }

                Button {
                    HapticManager.light()
                    Task { await sendMessage() }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .scaledFont(size: 28)
                        .foregroundColor(canSend ? .brandGreen : .brandTextDim)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .disabled(!canSend)
                .accessibilityLabel("Send message")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.brandSurface)
        }
    }

    // MARK: - Helpers
    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespaces).isEmpty && !vm.isSending && !vm.isAtLimit
    }

    private func sendMessage() async {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        inputText = ""
        inputFocused = false
        await vm.send(text: text)
    }

    // MARK: - Toolbar
    private var titleToolbar: some ToolbarContent {
        Group {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 6) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .scaledFont(size: 13)
                        .foregroundColor(.brandPurple)
                    Text("Chat")
                        .scaledFont(size: 17, weight: .bold, design: .monospaced)
                        .foregroundColor(.brandText)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 10) {
                    VStack(spacing: 1) {
                        Text("\(vm.remaining)")
                            .scaledFont(size: 13, weight: .bold, design: .monospaced)
                            .foregroundColor(vm.remaining <= 5 ? .brandRed : .brandText)
                        Text("left")
                            .scaledFont(size: 8, design: .monospaced)
                            .foregroundColor(.brandTextDim)
                    }
                    .frame(width: 40, height: 40)
                    .background(Color.brandSurface2)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.brandBorder, lineWidth: 1))

                    if !vm.messages.isEmpty {
                        Button("Clear") {
                            HapticManager.warning()
                            vm.clear()
                        }
                        .scaledFont(size: 12, design: .monospaced)
                        .foregroundColor(.brandTextMuted)
                    }
                }
            }
        }
    }
}

// MARK: - Chip flow layout (pill-style, wraps like web)
struct ChipFlowView: View {
    let chips: [String]
    let disabled: Bool
    let onTap: (String) -> Void

    @State private var containerWidth: CGFloat = 320

    private func chipWidth(_ text: String) -> CGFloat {
        CGFloat(text.count) * 6.6 + 26
    }

    private func computeRows(width: CGFloat) -> [[String]] {
        var rows: [[String]] = [[]]
        var rowUsed: CGFloat = 0
        let gap: CGFloat = 8
        for chip in chips {
            let w = chipWidth(chip) + gap
            if rowUsed + w > width + gap, !rows.last!.isEmpty {
                rows.append([])
                rowUsed = 0
            }
            rows[rows.count - 1].append(chip)
            rowUsed += w
        }
        return rows
    }

    var body: some View {
        let rows = computeRows(width: containerWidth)
        VStack(alignment: .leading, spacing: 8) {
            ForEach(rows.indices, id: \.self) { r in
                HStack(spacing: 8) {
                    ForEach(rows[r], id: \.self) { chip in
                        chipButton(chip)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            GeometryReader { geo in
                Color.clear.onAppear { containerWidth = geo.size.width }
            }
        )
    }

    private func chipButton(_ text: String) -> some View {
        Button { onTap(text) } label: {
            Text(text)
                .scaledFont(size: 11, design: .monospaced)
                .foregroundColor(disabled ? .brandTextDim : .brandText)
                .lineLimit(1)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(disabled ? Color.brandBorder.opacity(0.4) : Color.brandBorder, lineWidth: 1)
                )
        }
        .disabled(disabled)
    }
}

// MARK: - Message bubble
struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        if message.role == .user {
            userBubble
        } else if message.hasPicksResponse {
            picksView
        } else {
            assistantBubble
        }
    }

    private var userBubble: some View {
        HStack {
            Spacer(minLength: 48)
            Text(message.content)
                .scaledFont(size: 13, design: .monospaced)
                .foregroundColor(.brandBackground)
                .lineSpacing(4)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.brandGreen)
                .cornerRadius(14)
        }
    }

    private var assistantBubble: some View {
        HStack {
            Text(message.content)
                .scaledFont(size: 13, design: .monospaced)
                .foregroundColor(.brandText)
                .lineSpacing(4)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.brandSurface)
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.brandBorder, lineWidth: 1))
            Spacer(minLength: 48)
        }
    }

    private var picksView: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let picks = message.picks {
                ForEach(picks) { pick in
                    PickResponseCard(pick: pick)
                }
            }
            if let parlay = message.parlay {
                ParlayCard(parlay: parlay)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Pick response card
struct PickResponseCard: View {
    let pick: AdvisorPick

    private var confidenceColor: Color {
        switch pick.confidence {
        case "HIGH":   return .brandGreen
        case "MEDIUM": return .brandAmber
        case "SPEC":   return .brandPurple
        default:       return .brandTextMuted
        }
    }

    private var formattedLine: String {
        guard let line = pick.line else { return "" }
        return line == line.rounded() ? "\(Int(line))" : String(format: "%.1f", line)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Row 1: player + confidence badge
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(pick.player ?? "Unknown Player")
                        .scaledFont(size: 14, weight: .bold, design: .monospaced)
                        .foregroundColor(.brandText)
                    if let team = pick.team, let opp = pick.opponent {
                        Text("\(team) vs \(opp)")
                            .scaledFont(size: 11, design: .monospaced)
                            .foregroundColor(.brandTextDim)
                    }
                }
                Spacer()
                if let conf = pick.confidence {
                    Text(conf)
                        .scaledFont(size: 9, weight: .bold, design: .monospaced)
                        .foregroundColor(confidenceColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(confidenceColor.opacity(0.12))
                        .cornerRadius(4)
                }
            }

            // Row 2: market label + lean + line + odds
            HStack(spacing: 6) {
                if let label = pick.marketLabel {
                    Text(label.uppercased())
                        .scaledFont(size: 9, design: .monospaced)
                        .foregroundColor(.brandTextDim)
                }
                if let lean = pick.lean {
                    Text(lean)
                        .scaledFont(size: 10, weight: .bold, design: .monospaced)
                        .foregroundColor(lean == "OVER" ? .brandGreen : .brandRed)
                }
                if !formattedLine.isEmpty {
                    Text(formattedLine)
                        .scaledFont(size: 10, design: .monospaced)
                        .foregroundColor(.brandText)
                }
                if let odds = pick.odds {
                    Text(odds)
                        .scaledFont(size: 10, design: .monospaced)
                        .foregroundColor(.brandTextDim)
                }
            }

            // Reasoning
            if let reasoning = pick.reasoning, !reasoning.isEmpty {
                Text(reasoning)
                    .scaledFont(size: 11, design: .monospaced)
                    .foregroundColor(.brandTextMuted)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Signal chips
            if let signals = pick.signals, !signals.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(signals, id: \.self) { signal in
                            Text(signal)
                                .scaledFont(size: 9, design: .monospaced)
                                .foregroundColor(.brandTextDim)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Color.brandSurface2)
                                .cornerRadius(4)
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(Color.brandSurface)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.brandBorder, lineWidth: 1))
    }
}

// MARK: - Parlay card
struct ParlayCard: View {
    let parlay: AdvisorParlay

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack(alignment: .top) {
                Text("SUGGESTED PARLAY")
                    .scaledFont(size: 9, weight: .bold, design: .monospaced)
                    .foregroundColor(.brandAmber)
                    .kerning(1)
                Spacer()
                if let odds = parlay.combinedOdds {
                    Text(odds)
                        .scaledFont(size: 16, weight: .bold, design: .monospaced)
                        .foregroundColor(.brandAmber)
                }
            }

            // Legs
            if let legs = parlay.legs, !legs.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(legs, id: \.self) { leg in
                        HStack(alignment: .top, spacing: 7) {
                            Circle()
                                .fill(Color.brandAmber)
                                .frame(width: 4, height: 4)
                                .padding(.top, 5)
                            Text(leg)
                                .scaledFont(size: 11, design: .monospaced)
                                .foregroundColor(.brandText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }

            // Reasoning
            if let reasoning = parlay.reasoning, !reasoning.isEmpty {
                Text(reasoning)
                    .scaledFont(size: 11, design: .monospaced)
                    .foregroundColor(.brandTextMuted)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .background(Color.brandAmber.opacity(0.06))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.brandAmber.opacity(0.3), lineWidth: 1))
    }
}

// MARK: - Typing indicator
struct TypingIndicator: View {
    @State private var animate = false

    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3) { i in
                    Circle()
                        .fill(Color.brandTextDim)
                        .frame(width: 6, height: 6)
                        .offset(y: animate ? -3 : 0)
                        .animation(
                            .easeInOut(duration: 0.5)
                            .repeatForever()
                            .delay(Double(i) * 0.15),
                            value: animate
                        )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.brandSurface)
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.brandBorder, lineWidth: 1))

            Spacer(minLength: 48)
        }
        .onAppear { animate = true }
    }
}
