# Study Money iPhone app

This Xcode project hosts the existing study site in a `WKWebView`. When the site's study timer starts, the web page sends the subject and its start timestamp to the native app. The app starts one Live Activity; stopping the timer ends it. The Live Activity shows elapsed study time in the Dynamic Island and on the Lock Screen.

The existing timer is a stopwatch, so the Live Activity displays elapsed time (time studied), not a countdown to a preset end time.

The home screen app name is **Study Money**. Its app icon uses the supplied glass piggy-bank image. The WKWebView fills the screen beneath the iOS status and home-indicator regions so the site's page background continues to the display edges.

The Lock Screen Live Activity has pause/resume and save controls. The app passes these actions to the website as `FORMStudyTimerPauseRequested`, `FORMStudyTimerResumeRequested`, and `FORMStudyTimerSaveRequested` events and opens the app when a control is tapped. The website must handle these events and persist the save request; its source is not part of this repository, so website-side saving still needs integration and device verification.

## Finish in Xcode

1. Open `FORMStudy.xcodeproj` on a Mac with Xcode 26 or later to build the iOS 26 Liquid Glass controls.
2. Select the `FORMStudy` project, then keep the configured Bundle Identifiers and select the same Personal Team for both `FORMStudy` and `FORMStudyWidget` under **Signing & Capabilities**.
3. Choose an iPhone simulator or connected iPhone and build/run the `FORMStudy` scheme.
4. Sign in to the study site in the app if prompted. Start a timer from the page; the Live Activity should appear. Stop the timer to dismiss it.

Live Activities must be enabled in iOS Settings. They are displayed only while the website timer is running. This environment cannot compile or sign the iOS targets; the final build, signing, and device test happen in Xcode.

## Project layout

- `FORMStudy/`: SwiftUI app and site `WKWebView` bridge.
- `FORMStudyWidget/`: Lock Screen and Dynamic Island Live Activity UI.
- `FORMStudy/StudyTimerAttributes.swift` is included in both targets.
- `web/`: reserved for the existing website source after the owner exports it; no web source is in this repository yet.
- `docs/architecture.md`: shared iOS/web data boundary and three-tab integration constraints.
- `docs/FORM_CODEX_HANDOFF.md`: the supplied product requirements, recorded as a checklist.
- `AGENTS.md`: repository-wide change and data-protection guidance.

GitHub `main` is the shared source of truth for application source, specs, and setup instructions. Do not commit deployed-site data, real study records, credentials, or signing keys. The exact Web export steps and required files are in [`web/README.md`](web/README.md).

## Updated device setup

See [DEVICE_SETUP.md](DEVICE_SETUP.md) for Japanese signing, build, device test, and website state synchronization instructions.

The native bridge requests the current timer state on page load and foreground entry using the `FORMStudyTimerStateRequested` window event. The website must respond with its authoritative start/stop message, and also publish state after authentication and timer restoration. This website integration has not been verified. Native messages are reconciled by one worker to avoid concurrent Activity creation, and existing matching activities are reused.

This revision has passed project structure checks, not Swift compilation or device testing: the cloud machine is Linux and has no Xcode or iOS SDK.
