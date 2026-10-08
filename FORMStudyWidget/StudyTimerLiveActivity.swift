import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

@main
struct StudyTimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: StudyTimerAttributes.self) { context in
            HStack(spacing: 10) {
                Button(intent: ToggleStudyTimerIntent(
                    subject: context.attributes.subject,
                    startedAtMilliseconds: context.state.startedAtMilliseconds,
                    shouldRun: !context.state.isRunning
                )) {
                    Image(systemName: context.state.isRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.circle)
                .controlSize(.mini)
                .tint(.orange)
                .frame(width: 36, height: 36)
                .accessibilityLabel(context.state.isRunning ? "停止" : "再開")

                Button(intent: SaveStudyTimerIntent(
                    subject: context.attributes.subject,
                    startedAtMilliseconds: context.state.startedAtMilliseconds
                )) {
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.circle)
                .controlSize(.mini)
                .tint(.white)
                .frame(width: 36, height: 36)
                .accessibilityLabel("停止して記録を保存")

                Spacer(minLength: 8)
                timerText(context.state)
                    .font(.system(size: 34, weight: .regular, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .foregroundStyle(.orange)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .activityBackgroundTint(.black)
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
                        timerText(context.state)
                            .monospacedDigit()
                            .font(.system(.title3, design: .rounded, weight: .semibold))
                    }
                    HStack(spacing: 10) {
                        Button(intent: ToggleStudyTimerIntent(
                            subject: context.attributes.subject,
                            startedAtMilliseconds: context.state.startedAtMilliseconds,
                            shouldRun: !context.state.isRunning
                        )) {
                            Label(context.state.isRunning ? "停止" : "再開",
                                  systemImage: context.state.isRunning ? "pause.fill" : "play.fill")
                                .modifier(InteractiveCapsuleGlass(tint: .white))
                        }
                        Button(intent: SaveStudyTimerIntent(
                            subject: context.attributes.subject,
                            startedAtMilliseconds: context.state.startedAtMilliseconds
                        )) {
                            Label("保存", systemImage: "bookmark.fill")
                                .modifier(InteractiveCapsuleGlass(tint: .white))
                        }
                    }
                }
            } compactLeading: {
                Text(context.attributes.subject.japaneseName)
                    .font(.caption2)
            } compactTrailing: {
                timerText(context.state)
                    .monospacedDigit()
                    .frame(maxWidth: 52)
            } minimal: {
                Image(systemName: "book.closed.fill")
                    .accessibilityLabel("\(context.attributes.subject.japaneseName)を学習中")
            }
            .keylineTint(.white)
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

private struct InteractiveCapsuleGlass: ViewModifier {
    let tint: Color

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.padding(.horizontal, 12).padding(.vertical, 8)
                .glassEffect(.regular.tint(tint.opacity(0.16)).interactive(), in: Capsule())
        } else {
            content.padding(.horizontal, 12).padding(.vertical, 8)
                .background(tint.opacity(0.12), in: Capsule())
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
