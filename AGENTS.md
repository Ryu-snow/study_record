# Repository guidance

This repository is the shared source of truth for the Study Money iOS app and, once exported, its web app. The iOS Xcode project currently lives at the repository root. Put the web app source under `web/`; do not move the Xcode project just to make the layout symmetric.

## Before changing behavior

- Inspect the current iOS and web implementations, API routes, database schema, and migrations. Do not infer endpoint names, database shape, reward rules, or client state from comments or screenshots.
- Treat the existing web database and authenticated web session as authoritative until inspected source proves otherwise. Preserve existing study records and make data migrations explicit and reversible.
- Keep the single WKWebView and its default website data store unless there is a tested design for session, timer, and record synchronization. Do not instantiate one independent website per tab.
- Keep Live Activity changes consistent with server persistence. A save action should be idempotent, report success/failure, and dismiss the Activity only after save confirmation.
- Use `Asia/Tokyo` for day boundaries and morning reward eligibility. Validate any reward-affecting action on the server as well as the client.
- Use SwiftUI's native `TabView` for the iOS 26 tab bar. Keep Liquid Glass in native controls; do not imitate it with web CSS.

## Protect user data and credentials

- Never commit `.env` files, API tokens, signing keys, production databases, real study records, or exported account data.
- Commit `.env.example` with placeholder names only. Keep database schema and migrations, not database snapshots.
- Preserve uncommitted user changes and review `git status` before and after edits.

## Verification and reporting

- Run the relevant web checks from `web/` and iOS build from the repository root when those source trees and toolchains are available.
- The iOS project requires macOS/Xcode. If the current environment lacks them, report the exact commands that remain unrun.
- Separate inspected facts from handoff notes and unverified assumptions. Do not claim a workflow works until the app, web API, and persistence path have been exercised together.
