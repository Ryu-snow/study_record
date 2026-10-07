import ActivityKit
import CoreFoundation
import OSLog
import SwiftUI
import UIKit
import WebKit

@MainActor
struct StudyWebView: UIViewRepresentable {
    static let siteHost = "study-form-ryu.ryukawasaki1023.chatgpt.site"

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        // The default data store retains website cookies and local storage across launches.
        configuration.websiteDataStore = .default()
        configuration.userContentController.add(context.coordinator, name: "studyTimer")

        let webView = WKWebView(frame: .zero, configuration: configuration)
        context.coordinator.observe(webView)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.load(URLRequest(url: URL(string: "https://\(Self.siteHost)")!))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "studyTimer")
        webView.navigationDelegate = nil
        webView.uiDelegate = nil
        coordinator.stopObserving()
        // Do not end a running timer when the view is removed or the app backgrounds.
    }

    @MainActor
    final class Coordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate, WKUIDelegate {
        private weak var webView: WKWebView?
        private let logger = Logger(subsystem: "jp.ryukawasaki.formstudy", category: "WebView")

        func observe(_ webView: WKWebView) {
            self.webView = webView
            NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive),
                                                   name: UIApplication.didBecomeActiveNotification, object: nil)
        }

        func stopObserving() {
            NotificationCenter.default.removeObserver(self)
            webView = nil
        }

        @objc private func didBecomeActive() {
            StudyActivityController.retryPendingState()
            requestTimerState()
        }

        private func requestTimerState() {
            guard let webView, webView.url?.host == StudyWebView.siteHost else { return }
            // Optional synchronization protocol. The website must respond with its current
            // start/stop message, after restoring its timer state and authenticating the user.
            webView.evaluateJavaScript("window.dispatchEvent(new Event('FORMStudyTimerStateRequested'));") { _, error in
                if let error {
                    self.logger.error("Timer state request failed: \(error.localizedDescription, privacy: .public)")
                }
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            requestTimerState()
        }

        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                     for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            // HTTPS links opening a new window use the same authenticated web session.
            if navigationAction.targetFrame == nil,
               navigationAction.request.url?.scheme?.lowercased() == "https" {
                webView.load(navigationAction.request)
            }
            return nil
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            logger.error("Website loading failed: \(error.localizedDescription, privacy: .public)")
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            logger.error("Website navigation failed: \(error.localizedDescription, privacy: .public)")
        }

        func userContentController(_ userContentController: WKUserContentController,
                                   didReceive message: WKScriptMessage) {
            guard message.name == "studyTimer",
                  message.frameInfo.isMainFrame,
                  message.frameInfo.securityOrigin.protocol == "https",
                  message.frameInfo.securityOrigin.host == StudyWebView.siteHost,
                  let body = message.body as? [String: Any],
                  let action = body["action"] as? String else { return }

            if action == "stop" {
                StudyActivityController.setTimer(nil)
                return
            }

            guard action == "start",
                  let subject = body["subject"] as? String,
                  ["english", "math", "chemistry", "physics"].contains(subject),
                  let startedAt = body["startedAt"] as? NSNumber,
                  CFGetTypeID(startedAt) != CFBooleanGetTypeID() else { return }
            let milliseconds = startedAt.doubleValue
            guard milliseconds.isFinite, milliseconds > 0,
                  milliseconds <= Date().timeIntervalSince1970 * 1_000 + 60_000 else {
                logger.error("Rejected invalid study timer timestamp")
                return
            }
            StudyActivityController.setTimer(.init(subject: subject, startedAtMilliseconds: milliseconds))
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url, url.scheme?.lowercased() == "https" else {
                decisionHandler(.cancel)
                return
            }
            // Preserve HTTPS authentication redirects in the same persistent web session.
            decisionHandler(.allow)
        }
    }
}

@MainActor
enum StudyActivityController {
    struct TimerState: Equatable {
        let subject: String
        let startedAtMilliseconds: Double

        func matches(_ activity: Activity<StudyTimerAttributes>) -> Bool {
            activity.attributes.subject == subject &&
            abs(activity.content.state.startedAtMilliseconds - startedAtMilliseconds) < 1
        }
    }

    private static let logger = Logger(subsystem: "jp.ryukawasaki.formstudy", category: "LiveActivity")
    private static var desiredTimer: TimerState?
    private static var revision: UInt64 = 0
    private static var worker: Task<Void, Never>?
    private static var hasReceivedState = false

    static func setTimer(_ timer: TimerState?) {
        hasReceivedState = true
        desiredTimer = timer
        revision &+= 1
        startWorker()
    }

    static func retryPendingState() {
        // Do not infer the website's current timer from an old Activity or cached start.
        guard hasReceivedState else { return }
        revision &+= 1
        startWorker()
    }

    private static func startWorker() {
        guard worker == nil else { return }
        worker = Task { await reconcile() }
    }

    private static func reconcile() async {
        while true {
            let currentRevision = revision
            let timer = desiredTimer
            // Adopt at most one matching existing Activity, including after app relaunch.
            var retained: Activity<StudyTimerAttributes>?
            for activity in Activity<StudyTimerAttributes>.activities {
                if let timer, timer.matches(activity), retained == nil,
                   activity.activityState == .active || activity.activityState == .stale {
                    retained = activity
                } else {
                    await activity.end(nil, dismissalPolicy: .immediate)
                }
            }
            // An incoming stop or a different start invalidates work suspended at an await.
            if currentRevision != revision { continue }
            if let timer, retained == nil {
                if UIApplication.shared.applicationState == .active,
                   ActivityAuthorizationInfo().areActivitiesEnabled {
                    let attributes = StudyTimerAttributes(subject: timer.subject)
                    let state = StudyTimerAttributes.ContentState(startedAtMilliseconds: timer.startedAtMilliseconds)
                    do {
                        _ = try Activity.request(attributes: attributes,
                                                 content: ActivityContent(state: state, staleDate: nil),
                                                 pushType: nil)
                    } catch {
                        logger.error("Live Activity request failed: \(error.localizedDescription, privacy: .public)")
                    }
                } else {
                    logger.notice("Live Activity creation deferred: app inactive or activities disabled")
                }
            }
            // No suspension between the revision check, request, and worker cleanup.
            worker = nil
            return
        }
    }
}
