import ActivityKit
import SwiftUI
import WidgetKit

@main
struct StudyTimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: StudyTimerAttributes.self) { context in
            HStack(spacing: 14) {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(context.attributes.subject.japaneseName)を学習中")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("集中タイマー")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
                Spacer(minLength: 8)
                Text(context.state.startedAt, style: .timer)
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .activityBackgroundTint(Color(red: 0.14, green: 0.14, blue: 0.15))
            .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(context.attributes.subject.japaneseName, systemImage: "book.closed.fill")
                        .font(.caption.weight(.semibold))
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("学習中").font(.caption2)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text("経過時間")
                        Spacer()
                        Text(context.state.startedAt, style: .timer)
                            .monospacedDigit()
                            .font(.system(.title3, design: .rounded, weight: .semibold))
                    }
                }
            } compactLeading: {
                Text(context.attributes.subject.japaneseName)
                    .font(.caption2)
            } compactTrailing: {
                Text(context.state.startedAt, style: .timer)
                    .monospacedDigit()
                    .frame(maxWidth: 52)
            } minimal: {
                Image(systemName: "book.closed.fill")
                    .accessibilityLabel("\(context.attributes.subject.japaneseName)を学習中")
            }
            .keylineTint(.white)
        }
    }
}

private extension String {
    var japaneseName: String {
        switch self {
        case "english": "英語"
        case "math": "数学"
        case "chemistry": "化学"
        case "physics": "物理"
        default: self
        }
    }
}
