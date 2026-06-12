import SwiftUI

/// A single labeled block of body text within a legal document.
/// `heading == nil` renders as a plain paragraph (e.g. the intro).
struct LegalSection: Identifiable {
    let id = UUID()
    let heading: String?
    let body: String

    init(_ body: String) {
        self.heading = nil
        self.body = body
    }

    init(_ heading: String, _ body: String) {
        self.heading = heading
        self.body = body
    }
}

/// Generic in-app reader for Privacy Policy / Terms of Service content.
/// Presented via NavigationLink from SettingsView, which provides a
/// standard back button automatically.
struct LegalDocumentView: View {
    let title: String
    let updated: String
    let sections: [LegalSection]

    var body: some View {
        ZStack {
            Color.brandBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text(updated)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.brandTextDim)

                    ForEach(sections) { section in
                        VStack(alignment: .leading, spacing: 6) {
                            if let heading = section.heading {
                                Text(heading)
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    .foregroundColor(.brandText)
                            }
                            Text(section.body)
                                .font(.system(size: 13))
                                .foregroundColor(.brandTextMuted)
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    Divider().background(Color.brandBorder)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("CONTACT")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.brandTextDim)
                            .kerning(1.5)
                        Text("jdsony1126@gmail.com")
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(.brandGreen)
                    }
                    .padding(.bottom, 24)
                }
                .padding(16)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .colorScheme(.dark)
    }
}

// MARK: - Content

extension LegalDocumentView {
    static let privacyPolicy = LegalDocumentView(
        title: "Privacy Policy",
        updated: "Last updated: June 11, 2026",
        sections: [
            LegalSection(
                "Prop Scout MLB (\"the App\") is a private research and analytics tool for Major League Baseball sportsbook odds, statistics, and pick tracking. Access is provided to authorized users by their organization's administrator — there is no public sign-up. This Privacy Policy explains what information the App collects, how it is used, and how it is protected."
            ),
            LegalSection(
                "1. Information We Collect",
                """
                The App collects only the information needed to operate your account:

                • Account credentials — the username and password issued to you by your administrator, used to sign in.
                • App preferences — settings you choose, such as your preferred sportsbook.
                • Pick log data — entries you create in the Picks tab (game, market, selection, odds, and result), used to track and grade your research picks over time.
                • Basic technical data — standard request metadata (such as app version) sent to our servers when the App communicates with its backend, used for support and troubleshooting.

                The App does not access your camera, photo library, contacts, location, or health data, and does not use advertising or analytics SDKs. The App does not request Sign in with Apple or any third-party login.
                """
            ),
            LegalSection(
                "2. How We Use Your Information",
                """
                • To authenticate you and keep you signed in.
                • To sync your preferences and pick history across your devices.
                • To operate, maintain, and improve the App.
                """
            ),
            LegalSection(
                "3. Sportsbook Odds & MLB Statistics",
                "The App displays sportsbook odds, lines, and MLB statistics sourced from third-party sports-data providers. These requests do not include any of your personal information — odds and statistics are fetched generically and displayed to you within the App."
            ),
            LegalSection(
                "4. Data Sharing",
                "We do not sell, rent, or share your personal information with third parties for marketing or advertising purposes. Information is stored on our backend servers solely to operate the App for authorized users."
            ),
            LegalSection(
                "5. Data Storage & Security",
                "All communication between the App and our backend is encrypted via HTTPS. Passwords are stored using industry-standard hashing and are never stored or transmitted in plain text. Access to backend systems is restricted to authorized administrators."
            ),
            LegalSection(
                "6. Data Retention & Account Management",
                "Because accounts are provisioned and managed by your organization's administrator (there is no self-service sign-up), account data is retained while your account remains active. To request access to, correction of, or deletion of your data, please contact your administrator, who can also reach us directly if needed."
            ),
            LegalSection(
                "7. Children's Privacy",
                "The App is not directed to, and does not knowingly collect information from, children. Accounts are issued only to authorized adult users by an administrator."
            ),
            LegalSection(
                "8. Changes to This Policy",
                "We may update this Privacy Policy from time to time. The \"Last updated\" date at the top of this page reflects the most recent revision."
            )
        ]
    )

    static let termsOfService = LegalDocumentView(
        title: "Terms of Service",
        updated: "Last updated: June 11, 2026",
        sections: [
            LegalSection(
                "These Terms of Service (\"Terms\") govern your use of Prop Scout MLB (\"the App\"). By signing in and using the App, you agree to these Terms. If you do not agree, do not use the App."
            ),
            LegalSection(
                "1. Description of Service",
                "Prop Scout MLB is an informational research tool that displays sportsbook odds and lines, MLB statistics, AI-generated analysis, and lets you maintain a personal log of research \"picks\" graded against publicly available odds. The App does not place bets, hold funds, process payments, or connect to any sportsbook account — it does not facilitate real-money wagering of any kind."
            ),
            LegalSection(
                "2. Eligibility & Accounts",
                """
                • Accounts are provisioned by your organization's administrator. There is no public sign-up, and the App does not support self-registration.
                • You must be 21 years of age or older to use any sportsbook-related features of the App.
                • You are responsible for keeping your login credentials confidential. Contact your administrator if you believe your account has been compromised or if you need your access changed or removed.
                """
            ),
            LegalSection(
                "3. Acceptable Use",
                """
                You agree not to:

                • Use the App for any unlawful purpose, including underage or illegal gambling.
                • Attempt to access accounts, data, or systems you are not authorized to access.
                • Interfere with or disrupt the App or its backend services.
                """
            ),
            LegalSection(
                "4. Informational Use Only — Not Gambling or Financial Advice",
                "Prop Scout MLB is an informational research tool. Picks, odds, and AI-generated analysis are provided for entertainment and informational purposes only and do not constitute gambling, financial, or betting advice. Any decisions you make based on information in the App are made at your own discretion and risk.\n\nIf you or someone you know has a gambling problem, call 1-800-GAMBLER."
            ),
            LegalSection(
                "5. Third-Party Data",
                "Sportsbook odds, lines, and MLB statistics displayed in the App are sourced from third-party providers. While we aim for accuracy, we do not guarantee that this data is complete, current, or error-free, and we are not responsible for decisions made in reliance on it."
            ),
            LegalSection(
                "6. Disclaimer of Warranties & Limitation of Liability",
                "The App is provided \"as is\" and \"as available,\" without warranties of any kind, express or implied. To the fullest extent permitted by law, we are not liable for any indirect, incidental, or consequential damages arising from your use of, or inability to use, the App."
            ),
            LegalSection(
                "7. Termination",
                "Your administrator may suspend or terminate your access to the App at any time. We may also suspend access to protect the security or integrity of the service."
            ),
            LegalSection(
                "8. Changes to These Terms",
                "We may update these Terms from time to time. The \"Last updated\" date at the top of this page reflects the most recent revision. Continued use of the App after changes take effect constitutes acceptance of the revised Terms."
            )
        ]
    )
}

#Preview {
    NavigationView {
        LegalDocumentView.privacyPolicy
    }
}
