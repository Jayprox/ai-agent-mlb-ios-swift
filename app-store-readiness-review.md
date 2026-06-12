# App Store readiness review — Prop Scout MLB

Scope: code/config review for App Review risk areas. Items are split into
**code fixes** (I can make these) and **submission/account items** (handled
in App Store Connect or by you, not in code).

## Good / no action needed

- **HTTPS only** — `Endpoints.baseURL` is `https://...`, no ATS exceptions
  (`NSAppTransportSecurity`) present — default secure ATS applies.
- **No privacy-sensitive APIs** — no camera, photo library, location,
  contacts, health, or tracking (ATT) usage, so no
  `NSxxxUsageDescription` strings are needed.
- **No third-party SSO** — login is username/password against your own
  backend, so Sign in with Apple (Guideline 4.8) is not required.
- **App icon** — complete set (universal 1024×1024 + dark + tinted
  variants), `UILaunchScreen_Generation = YES`.
- **No real-money gambling facilitation** — app shows odds/analysis and lets
  users log their own picks for tracking; it doesn't place bets, hold
  balances, or link sportsbook accounts. This keeps it out of Guideline
  5.6's licensed real-money-gaming bucket.
- Swift 5, `objectVersion = 77`, Xcode 26.5 — current toolchain, no stale
  project settings.

## Findings — code fixes (will do, pending your go-ahead)

1. **No responsible-gambling disclaimer.** The app's core content is
   sportsbook odds, lines, and a "Picks" log graded win/loss against those
   odds. Apps in this space commonly include a short disclaimer
   ("Informational/research tool — not gambling advice. If you have a
   gambling problem, call 1-800-GAMBLER") in Settings or a persistent
   footer. Not strictly required by a guideline number, but it directly
   supports the **age rating** (see below) and is a common reviewer ask for
   odds/picks apps.

2. **No privacy policy / terms link in-app.** App Store Connect requires a
   privacy policy URL in your app's metadata regardless, but it's good
   practice (and sometimes checked by reviewers) to also surface a link from
   Settings. I can add a Settings row once you have a URL to point to.

3. **Version string shows "1.0.0 MVP"** in Settings → App section. Cosmetic,
   but "MVP" reads as unfinished to a reviewer. Recommend changing to just
   "1.0.0" (or whatever you're submitting as).

4. **8 tabs in the main `TabView`.** On iPhone, `TabView` only shows 4-5 tabs
   before collapsing the rest into "More" — this changes navigation vs. the
   web app's horizontal-scroll tab bar. Not a rejection risk, but worth a
   decision: keep as-is (iOS will auto-generate "More"), or consolidate to
   ~5 primary tabs with the rest reachable via navigation.

## Findings — submission/account items (not code)

5. **Age rating / "Gambling and Contests" content descriptor.** Because the
   app displays sportsbook odds and lines prominently, the App Store Connect
   age-rating questionnaire should reflect "Frequent/Intense" gambling-themed
   content, which typically results in a 17+ rating. This is set in App
   Store Connect, not in code — flagging so it isn't missed at submission.

6. **Account deletion (Guideline 5.1.1(v)).** Confirmed: **accounts are
   provisioned by an admin** — there's no self-service sign-up anywhere (iOS
   or web). Per Apple's guidance, 5.1.1(v) only kicks in for apps that
   support account *creation*; admin-provisioned-only accounts generally
   don't trigger the in-app deletion requirement. Still worth a one-line
   note in the "App Review Information" section of App Store Connect (e.g.,
   "Accounts are issued by the team admin; end users cannot self-register or
   self-delete — contact [admin email] for account changes") so a reviewer
   doesn't flag the missing sign-up/delete flow as a bug.

   Optional polish: a small line on the login screen — "Accounts are
   provisioned by your administrator" — would make this clear to both
   reviewers and real users who land on the login screen without
   credentials. I can add this if you'd like.

7. **Reviewer demo account.** Since accounts are admin-issued, App Store
   Connect's "App Review Information" needs a working username/password the
   admin has created for the reviewer, so they can log in and see real
   content (Board, Picks, etc.). This is just a credential the admin
   generates — no code change.

8. **`IPHONEOS_DEPLOYMENT_TARGET = 26.5`** — pins to the very latest iOS
   point release, which narrows your install base to users who've updated to
   26.5. Not a rejection reason, but worth confirming this is intentional
   (e.g., a 26.5-only API is in use) vs. leaving it at the Xcode default.

## Suggested next step

I can implement #1–3 now (disclaimer text + placement, privacy/terms
Settings row scaffold, version string cleanup) while you confirm the URL for
#2 and the account-creation question for #6. Want me to proceed with those
three?
