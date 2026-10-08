# FORM / Study Money product handoff

Source: `FORM_Codex_Handoff.zip`, updated 2026-10-08. This is the requested product and integration checklist; implementation details remain subject to verification against the current web source.

## Product requirements

- Home: cumulative savings, today's learning time and weekday/weekend goal, remaining time, subject stack, seven-day bars and target line, and seven-day achievement count/total.
- Focus: elapsed timer, four subjects, subject selection shared with manual time entry, native hour/minute selection, and subject totals.
- History: Japan-time date selection, chronological sessions, edit/delete by date/subject/start/duration, and subdued weekday/weekend goal settings (10h/15h defaults).
- Before replacing goal settings, verify whether the current site instead stores a weekend/weekday choice per date; preserve that behavior or confirm a migration.
- Rewards: daily total gives 100 yen at 10h and 200 yen at 15h without stacking; the 5 a.m. wake reward adds 100 yen only for a check from 04:30 to 05:15 Asia/Tokyo. At 15h plus the wake check, total reward is 300 yen. These are achievements, not payments. Recalculate derived totals after session edits/deletions and validate reward eligibility on the server.
- Keep English, Math, Chemistry, Physics, timer, manual entry, saved session CRUD, date switching, per-subject and seven-day aggregates, goal checks, savings, Live Activity, and web persistence.

## Integration constraints

- SwiftUI owns the native iOS 26 Liquid Glass `TabView`; web CSS must not imitate it.
- The current app has a single WKWebView with the default persistent website data store. Keep one authenticated web state and do not create three independent WebViews without proven timer/data synchronization.
- The existing site-to-native message name is `studyTimer`; documented messages are `start` with `subject` and epoch-millisecond `startedAt`, and `stop`.
- Pause/resume/save website events and any API endpoint must be checked against the exported site's actual code. The current native `/api/study` mention is only a source comment, not a verified route.
- Treat the site database as the source of truth. Save should be idempotent and only dismiss Live Activity after durable save confirmation.
