import ActivityKit
import Foundation

struct StudyTimerAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        /// Epoch milliseconds supplied by the study site's existing timer.
        var startedAtMilliseconds: Double
        var accumulatedSeconds: Double
        var isRunning: Bool
        var resumedAtMilliseconds: Double?

        init(startedAtMilliseconds: Double) {
            self.startedAtMilliseconds = startedAtMilliseconds
            accumulatedSeconds = 0
            isRunning = true
            resumedAtMilliseconds = startedAtMilliseconds
        }

        private enum CodingKeys: String, CodingKey {
            case startedAtMilliseconds, accumulatedSeconds, isRunning, resumedAtMilliseconds
        }

        init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            startedAtMilliseconds = try values.decode(Double.self, forKey: .startedAtMilliseconds)
            accumulatedSeconds = try values.decodeIfPresent(Double.self, forKey: .accumulatedSeconds) ?? 0
            isRunning = try values.decodeIfPresent(Bool.self, forKey: .isRunning) ?? true
            resumedAtMilliseconds = try values.decodeIfPresent(Double.self, forKey: .resumedAtMilliseconds)
                ?? (isRunning ? startedAtMilliseconds : nil)
        }

        func encode(to encoder: Encoder) throws {
            var values = encoder.container(keyedBy: CodingKeys.self)
            try values.encode(startedAtMilliseconds, forKey: .startedAtMilliseconds)
            try values.encode(accumulatedSeconds, forKey: .accumulatedSeconds)
            try values.encode(isRunning, forKey: .isRunning)
            try values.encodeIfPresent(resumedAtMilliseconds, forKey: .resumedAtMilliseconds)
        }

        var elapsedSeconds: Double {
            accumulatedSeconds + (isRunning ? max(0, Date().timeIntervalSince(resumedAt)) : 0)
        }

        var timerReferenceDate: Date {
            resumedAt.addingTimeInterval(-accumulatedSeconds)
        }

        var startedAt: Date {
            Date(timeIntervalSince1970: startedAtMilliseconds / 1_000)
        }

        private var resumedAt: Date {
            Date(timeIntervalSince1970: (resumedAtMilliseconds ?? startedAtMilliseconds) / 1_000)
        }
    }

    var subject: String
}
