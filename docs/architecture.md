# Study Money shared workspace

## Current repository facts

- This GitHub repository currently contains the iOS wrapper at its root: `FORMStudy.xcodeproj`, `FORMStudy/`, and `FORMStudyWidget/`.
- `FORMStudy` hosts `https://study-form-ryu.ryukawasaki1023.chatgpt.site` in one `WKWebView` using `WKWebsiteDataStore.default()`, which keeps the site's login data in that web session.
- The site sends `start` and `stop` messages through `window.webkit.messageHandlers.studyTimer`. `StudyWebView.swift` bridges those to ActivityKit.
- The widget extension embeds the Live Activity UI. `StudyTimerAttributes.swift` is shared by the app and extension. The minimum deployment target is iOS 18.0; the iOS 26 Liquid Glass path has a legacy visual fallback.
- Live Activity pause/resume/save intents and custom URL handoff exist in the native source. This repository does not contain the website listener or persistence implementation for those controls.
- A comment in `StudyTimerControls.swift` mentions `/api/study`; the actual web route and request contract have not been verified. Do not build against that comment as if it were an implemented API.

## Web source and data boundary

The ChatGPT Sites project is identified in the handoff as `appgprj_6ab22c8cfe108191a6fd1bfdb364bbe4`. The deployed site URL alone does not provide its source, API definitions, database schema, or migrations. The site returned HTTP 403 from this environment, so its implementation could not be inspected here.

When the owner exports the project source, add it under `web/` without production data or secrets. The authenticated site's existing database remains the data source of truth. Record the real request and response shapes, auth/session behavior, schema, migrations, and local setup command in `web/README.md` after inspecting the export.

## Three-tab integration target

Use one authenticated web application state and one WKWebView session. The native `TabView` should switch Home, Focus, and History through a documented route/event/API contract implemented by the website. Do not load three copies of the site and assume cookies alone synchronize in-memory timers or unsaved forms.

Before moving page sections, map each existing feature to its current web component and API: savings/reward calculation, daily and seven-day aggregates, session CRUD, timer state, manual entry, and weekday/weekend goals. Keep edits and deletion on the existing persistence path and recalculate derived totals from saved sessions.

Check whether the current site sets a weekend/weekday goal per individual date. If so, document that behavior and resolve its relationship to the requested global weekday/weekend defaults before replacing the setting model.

## Live Activity persistence contract

The native UI may pause or resume its elapsed-time state, but the website and database must receive the same transition. Saving must send an idempotency key and the session's subject, original start, active duration, and applicable date to the real authenticated API. The web app should return a durable success response before the Live Activity is ended; failed requests should remain retryable without duplicate study records. Confirm this contract against the exported backend before changing the current native URL/event flow.

## Reward and date rules to verify in source

The handoff specifies Japan-time daily aggregation, 100 yen at 10 hours, 200 yen at 15 hours without stacking the 10-hour reward, plus 100 yen for a wake-up check available only from 04:30 through 05:15 Japan time. These are requirements to compare against the real implementation, not proof that the current website already enforces them. Corrections to a saved session must recalculate all affected totals and rewards.
