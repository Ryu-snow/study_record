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
        guard let activity = Activity<StudyTimerAttributes>.activities.first(where: {
            $0.attributes.subject == subject &&
            abs($0.content.state.startedAtMilliseconds - startedAtMilliseconds) < 1
        }) else {
            return .result(opensIntent: OpenURLIntent(url))
        }

        var state = activity.content.state
        if shouldRun && !state.isRunning {
            state.isRunning = true
            state.resumedAtMilliseconds = Date().timeIntervalSince1970 * 1_000
        } else if !shouldRun && state.isRunning {
            state.accumulatedSeconds = state.elapsedSeconds
            state.isRunning = false
            state.resumedAtMilliseconds = nil
        }
        await activity.update(ActivityContent(state: state, staleDate: nil))
        return .result(opensIntent: OpenURLIntent(url))
    }
}

@MainActor
struct StopStudyTimerIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "学習タイマーを停止"
    static var description = IntentDescription("アプリを開いてタイマーを停止し、学習記録を保存します。")

    @Parameter(title: "科目") var subject: String
    @Parameter(title: "開始時刻") var startedAtMilliseconds: Double

    init() {}

    init(subject: String, startedAtMilliseconds: Double) {
        self.subject = subject
        self.startedAtMilliseconds = startedAtMilliseconds
    }

    func perform() async throws -> some IntentResult {
        let url = studyTimerURL(action: "stop",
                                subject: subject,
                                startedAtMilliseconds: startedAtMilliseconds)
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
        let activity = Activity<StudyTimerAttributes>.activities.first(where: {
            $0.attributes.subject == subject &&
            abs($0.content.state.startedAtMilliseconds - startedAtMilliseconds) < 1
        })
        let elapsedSeconds = activity?.content.state.elapsedSeconds ?? 0
        // Keep the Live Activity visible until the website confirms and reflects the save.
        // The app URL below lets the authenticated WKWebView submit the record to /api/study.
        let url = studyTimerURL(action: "save", subject: subject,
                                startedAtMilliseconds: startedAtMilliseconds,
                                elapsedSeconds: elapsedSeconds)
        return .result(opensIntent: OpenURLIntent(url))
    }
}
