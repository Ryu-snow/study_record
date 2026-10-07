import ActivityKit
import Foundation

struct StudyTimerAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        /// Epoch milliseconds supplied by the study site's existing timer.
        var startedAtMilliseconds: Double

        var startedAt: Date {
            Date(timeIntervalSince1970: startedAtMilliseconds / 1_000)
        }
    }

    var subject: String
}
