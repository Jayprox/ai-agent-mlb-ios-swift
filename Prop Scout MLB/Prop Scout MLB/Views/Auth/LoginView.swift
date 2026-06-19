import SwiftUI

struct LoginView: View {
    @EnvironmentObject var auth: AuthViewModel

    @State private var username: String = ""
    @State private var password: String = ""
    @FocusState private var focused: Field?

    enum Field { case username, password }

    var body: some View {
        ZStack {
            Color.brandBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // MARK: Logo
                VStack(spacing: 8) {
                    Text("Chalk That")
                        .scaledFont(size: 28, weight: .bold, design: .monospaced)
                        .foregroundColor(.brandText)
                    Text("AI PROPS RESEARCH")
                        .scaledFont(size: 11, weight: .semibold, design: .monospaced)
                        .foregroundColor(.brandTextDim)
                        .kerning(2)
                }
                .padding(.bottom, 48)

                // MARK: Form card
                VStack(spacing: 16) {
                    // Username field
                    VStack(alignment: .leading, spacing: 6) {
                        Text("USERNAME")
                            .scaledFont(size: 10, weight: .semibold, design: .monospaced)
                            .foregroundColor(.brandTextDim)
                            .kerning(1.5)
                        TextField("", text: $username)
                            .textContentType(.username)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .focused($focused, equals: .username)
                            .submitLabel(.next)
                            .onSubmit { focused = .password }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(Color.brandSurface2)
                            .foregroundColor(.brandText)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(focused == .username ? Color.brandBlue : Color.brandBorder, lineWidth: 1)
                            )
                    }

                    // Password field
                    VStack(alignment: .leading, spacing: 6) {
                        Text("PASSWORD")
                            .scaledFont(size: 10, weight: .semibold, design: .monospaced)
                            .foregroundColor(.brandTextDim)
                            .kerning(1.5)
                        SecureField("", text: $password)
                            .textContentType(.password)
                            .focused($focused, equals: .password)
                            .submitLabel(.go)
                            .onSubmit { submitLogin() }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(Color.brandSurface2)
                            .foregroundColor(.brandText)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(focused == .password ? Color.brandBlue : Color.brandBorder, lineWidth: 1)
                            )
                    }

                    // Error message
                    if let error = auth.errorMessage {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .scaledFont(size: 12)
                            Text(error)
                                .scaledFont(size: 13)
                        }
                        .foregroundColor(.brandRed)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)
                    }

                    // Login button
                    Button(action: submitLogin) {
                        ZStack {
                            if auth.isLoading {
                                ProgressView()
                                    .tint(.brandBackground)
                            } else {
                                Text("SIGN IN")
                                    .scaledFont(size: 14, weight: .bold, design: .monospaced)
                                    .kerning(1.5)
                                    .foregroundColor(.brandBackground)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(canSubmit ? Color.brandGreen : Color.brandTextDim)
                        .cornerRadius(8)
                    }
                    .disabled(!canSubmit || auth.isLoading)
                    .padding(.top, 4)
                }
                .padding(24)
                .background(Color.brandSurface)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.brandBorder, lineWidth: 1)
                )
                .padding(.horizontal, 24)

                Spacer()

                // Footer
                VStack(spacing: 6) {
                    Text("Accounts are provisioned by your administrator")
                        .scaledFont(size: 11, design: .monospaced)
                        .foregroundColor(.brandTextDim)
                        .multilineTextAlignment(.center)
                    Text("⚡ Full live mode")
                        .scaledFont(size: 11, design: .monospaced)
                        .foregroundColor(.brandTextDim)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .colorScheme(.dark)
    }

    private var canSubmit: Bool {
        !username.trimmingCharacters(in: .whitespaces).isEmpty &&
        !password.isEmpty
    }

    private func submitLogin() {
        focused = nil
        guard canSubmit else { return }
        Task { await auth.login(username: username, password: password) }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
}
