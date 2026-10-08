import ActivityKit
import SwiftUI
import WidgetKit

@main
struct StudyTimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: StudyTimerAttributes.self) { context in
            HStack(alignment: .lastTextBaseline, spacing: 10) {
                Text(context.attributes.subject.japaneseName)
                    .font(.caption2.weight(.medium))
                    .lineLimit(1)

                timerText(context.state)
                    .font(.system(size: 44, weight: .regular, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .foregroundStyle(.orange)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .activityBackgroundTint(.black)
            .activitySystemActionForegroundColor(.orange)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.attributes.subject.japaneseName)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.orange)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    timerText(context.state)
                        .monospacedDigit()
                        .font(.system(.title2, design: .rounded, weight: .semibold))
                        .foregroundStyle(.orange)
                        .frame(maxWidth: .infinity)
                }
            } compactLeading: {
                Text(context.attributes.subject.japaneseName)
                    .font(.caption2)
                    .foregroundStyle(.orange)
            } compactTrailing: {
                timerText(context.state)
                    .monospacedDigit()
                    .foregroundStyle(.orange)
                    .frame(maxWidth: 52)
            } minimal: {
                Image(systemName: "book.closed.fill")
                    .foregroundStyle(.orange)
                    .accessibilityLabel("\(context.attributes.subject.japaneseName)を学習中")
            }
            .keylineTint(.orange)
        }
    }

    @ViewBuilder
    private func timerText(_ state: StudyTimerAttributes.ContentState) -> some View {
        if state.isRunning {
            Text(state.timerReferenceDate, style: .timer)
        } else {
            Text(elapsedLabel(state.elapsedSeconds))
        }
    }

    private func elapsedLabel(_ seconds: Double) -> String {
        let total = max(0, Int(seconds))
        return String(format: "%02d:%02d:%02d", total / 3_600, (total / 60) % 60, total % 60)
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
