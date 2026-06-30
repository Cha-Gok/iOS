import ActivityKit
import Domain
import SwiftUI
import WidgetKit

struct RecordingActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RecordingActivityAttributes.self) { context in
            LockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        Image(systemName: "mic.fill")
                            .foregroundColor(.red)
                        Text("녹음 중")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.displayDuration)
                        .font(.headline)
                        .monospacedDigit()
                        .foregroundColor(.white)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text(context.attributes.title)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
            } compactLeading: {
                Image(systemName: "mic.fill")
                    .foregroundColor(.red)
            } compactTrailing: {
                Text(context.state.displayDuration)
                    .monospacedDigit()
                    .foregroundColor(.red)
            } minimal: {
                Image(systemName: "mic.fill")
                    .foregroundColor(.red)
            }
        }
    }
}

struct LockScreenView: View {
    let context: ActivityViewContext<RecordingActivityAttributes>

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(context.attributes.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(context.state.isPaused ? "일시정지됨" : "녹음 중")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(context.state.displayDuration)
                .font(.title)
                .monospacedDigit()
                .foregroundColor(.primary)
        }
        .padding()
        .activityBackgroundTint(Color.black.opacity(0.6))
    }
}

private extension RecordingActivityAttributes.ContentState {
    var displayDuration: String {
        let duration = Int(duration)
        let hours = duration / 3600
        let minutes = (duration % 3600) / 60
        let seconds = duration % 60
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}
