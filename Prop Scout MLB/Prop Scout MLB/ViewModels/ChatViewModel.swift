import Foundation
import Combine

final class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isSending = false
    @Published var errorMessage: String? = nil
    @Published var messagesUsedToday: Int = 0
    @Published var maxMessages: Int = 20
    @Published var persona: String = "pro"   // "pro" | "lotto"

    var remaining: Int { max(0, maxMessages - messagesUsedToday) }
    var isAtLimit: Bool { messagesUsedToday >= maxMessages }

    private var slateDate: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "Pacific/Honolulu")
        return f.string(from: Date())
    }

    // MARK: - Send
    func send(text: String) async {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty, !isAtLimit else { return }

        let userMsg = ChatMessage(role: .user, content: text)

        // Build API history — use content only; skip messages with empty content (shouldn't happen but guard)
        let apiMessages = messages.suffix(7).compactMap { msg -> ChatAPIMessage? in
            let c = msg.content.trimmingCharacters(in: .whitespaces)
            guard !c.isEmpty else { return nil }
            return ChatAPIMessage(role: msg.role.rawValue, content: c)
        } + [ChatAPIMessage(role: "user", content: text)]

        DispatchQueue.main.async {
            self.messages.append(userMsg)
            self.isSending = true
            self.errorMessage = nil
        }

        let req = ChatRequest(messages: apiMessages, persona: persona, date: slateDate)

        do {
            let resp: ChatResponse = try await APIClient.shared.post(
                path: "/api/advisor",
                body: req
            )
            DispatchQueue.main.async {
                let type = resp.type ?? "message"
                if (type == "picks" || type == "lotto"), let picks = resp.picks, !picks.isEmpty {
                    // Structured picks response — store a compact text for API history context
                    let summary = picks.prefix(3).map {
                        "\($0.player ?? "?") \($0.lean ?? "") \($0.marketLabel ?? "")"
                    }.joined(separator: ", ")
                    let content = "Picks: \(summary)\(picks.count > 3 ? " +\(picks.count - 3) more" : "")"
                    self.messages.append(ChatMessage(
                        role: .assistant,
                        content: content,
                        picks: picks,
                        parlay: resp.parlay,
                        responseType: type
                    ))
                } else if let content = resp.content, !content.isEmpty {
                    self.messages.append(ChatMessage(role: .assistant, content: content))
                }
                if let used = resp.messagesUsedToday { self.messagesUsedToday = used }
                if let max  = resp.maxMessagesPerDay  { self.maxMessages = max }
                self.isSending = false
            }
        } catch let APIError.serverError(code, _) where code == 429 {
            DispatchQueue.main.async {
                self.messagesUsedToday = self.maxMessages
                self.errorMessage = "Daily limit reached — resets at midnight HI"
                self.isSending = false
            }
        } catch let error as APIError {
            DispatchQueue.main.async {
                self.errorMessage = error.errorDescription
                self.isSending = false
                self.messages.removeLast()
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isSending = false
                self.messages.removeLast()
            }
        }
    }

    // MARK: - Clear
    func clear() {
        messages = []
        errorMessage = nil
    }
}
