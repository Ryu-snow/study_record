import ActivityKit
import AppIntents
import Foundation

private func studyTimerURL(action: String, subject: String, startedAtMilliseconds: Double,
                           elapsedSeconds: Double? = nil) -> URL {
    var components = URLComponents()
    components.scheme = "studymoney"
    components.host = "timer"
    components.path = "/\(action)"
    components.queryItems = [
        URLQueryItem(name: "subject", value: subject),
        URLQueryItem(name: "startedAt", value: String(startedAtMilliseconds))
    ]
    if let elapsedSeconds {
        components.queryItems?.append(URLQueryItem(name: "elapsedSeconds", value: String(elapsedSeconds)))
    }
    return components.url ?? URL(string: "https://study-form-ryu.ryukawasaki1023.chatgpt.site")!
}

@MainActor
struct ToggleStudyTimerIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "学習タイマーを一時停止／再開"
    static var description = IntentDescription("Live Activity の学習時間を一時停止または再開します。")

    @Parameter(title: "科目") var subject: String
    @Parameter(title: "開始時刻") var startedAtMilliseconds: Double
    @Parameter(title: "再開") var shouldRun: Bool

    init() {}

    init(subject: String, startedAtMilliseconds: Double, shouldRun: Bool) {
        self.subject = subject
        self.startedAtMilliseconds = startedAtMilliseconds
        self.shouldRun = shouldRun
    }

    func perform() async throws -> some IntentResult {
        let url = studyTimerURL(action: shouldRun ? "resume" : "pause",
                                subject: subject,
                                startedAtMilliseconds: startedAtMilliseconds)
        // The website owns the timer state. Let its pause/resume request update the
        // database first; the WebView bridge mirrors the confirmed state back to ActivityKit.
        return .result(opensIntent: OpenURLIntent(url))
    }
}

@MainActor
struct SaveStudyTimerIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "学習記録を保存"
    static var description = IntentDescription("学習記録をサイトへ保存し、Live Activity を終了します。")

    @Parameter(title: "科目") var subject: String
    @Parameter(title: "開始時刻") var startedAtMilliseconds: Double

    init() {}

    init(subject: String, startedAtMilliseconds: Double) {
        self.subject = subject
        self.startedAtMilliseconds = startedAtMilliseconds
    }

    func perform() async throws -> some IntentResult {
        // Send the dedicated save request so the website can persist the elapsed
        // Live Activity time before it clears the timer and ends the activity.
        let activity = Activity<StudyTimerAttributes>.activities.first(where: {
            $0.attributes.subject == subject &&
            abs($0.content.state.startedAtMilliseconds - startedAtMilliseconds) < 1
        })
        let elapsedSeconds = activity?.content.state.elapsedSeconds
            ?? max(0, Date().timeIntervalSince1970 - startedAtMilliseconds / 1_000)
        let url = studyTimerURL(action: "save",
                                subject: subject,
                                startedAtMilliseconds: startedAtMilliseconds,
                                elapsedSeconds: elapsedSeconds)
        return .result(opensIntent: OpenURLIntent(url))
    }
}
