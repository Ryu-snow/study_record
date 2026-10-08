import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

@main
struct StudyTimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: StudyTimerAttributes.self) { context in
            VStack(spacing: 12) {
                HStack {
                    Label("\(context.attributes.subject.japaneseName)を学習中", systemImage: "book.closed.fill")
                        .font(.headline)
                    Spacer()
                    Text(context.state.isRunning ? "学習中" : "一時停止")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(context.state.isRunning ? .green : .orange)
                }
                HStack(spacing: 10) {
                    VStack(spacing: 3) {
                        Button(intent: ToggleStudyTimerIntent(
                            subject: context.attributes.subject,
                            startedAtMilliseconds: context.state.startedAtMilliseconds,
                            shouldRun: !context.state.isRunning
                        )) {
                            Image(systemName: context.state.isRunning ? "pause.fill" : "play.fill")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(.orange)
                                .frame(width: 42, height: 42)
                        }
                        .buttonStyle(.plain)
                        .modifier(InteractiveCircleGlass(tint: .orange, fallbackOpacity: 0.18))
                        .accessibilityLabel(context.state.isRunning ? "一時停止" : "再開")
                        Text(context.state.isRunning ? "一時停止" : "再開")
                            .font(.caption2)
                            .foregroundStyle(.white)
                    }

                    VStack(spacing: 3) {
                        Button(intent: StopStudyTimerIntent(
                            subject: context.attributes.subject,
                            startedAtMilliseconds: context.state.startedAtMilliseconds
                        )) {
                            Image(systemName: "stop.fill")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 42, height: 42)
                        }
                        .buttonStyle(.plain)
                        .modifier(InteractiveCircleGlass(tint: .white, fallbackOpacity: 0.15))
                        .accessibilityLabel("停止して記録")
                        Text("停止")
                            .font(.caption2)
                            .foregroundStyle(.white)
                    }

                    VStack(spacing: 3) {
                        Button(intent: SaveStudyTimerIntent(
                            subject: context.attributes.subject,
                            startedAtMilliseconds: context.state.startedAtMilliseconds
                        )) {
                            Image(systemName: "bookmark.fill")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 42, height: 42)
                        }
                        .buttonStyle(.plain)
                        .modifier(InteractiveCircleGlass(tint: .white, fallbackOpacity: 0.15))
                        .accessibilityLabel("記録を保存して終了")
                        Text("保存")
                            .font(.caption2)
                            .foregroundStyle(.white)
                    }

                    Spacer(minLength: 2)
                    timerText(context.state)
                        .font(.system(size: 36, weight: .regular, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.orange)
                }
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
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
                            Label(context.state.isRunning ? "一時停止" : "再開",
                                  systemImage: context.state.isRunning ? "pause.fill" : "play.fill")
                                .modifier(InteractiveCapsuleGlass(tint: .white))
                        }
                        Button(intent: StopStudyTimerIntent(
                            subject: context.attributes.subject,
                            startedAtMilliseconds: context.state.startedAtMilliseconds
                        )) {
                            Label("停止", systemImage: "stop.fill")
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

private struct InteractiveCircleGlass: ViewModifier {
    let tint: Color
    let fallbackOpacity: Double

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(.regular.tint(tint).interactive(), in: Circle())
        } else {
            content.background(tint.opacity(fallbackOpacity), in: Circle())
        }
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
