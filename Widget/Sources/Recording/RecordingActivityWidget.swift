import ActivityKit
import AppIntents
import Core
import Domain
import Presentation
import SwiftUI
import WidgetKit

struct RecordingActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RecordingActivityAttributes.self) { context in
            LockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // 다이내믹 아일랜드 확장형 (왼쪽)
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        Button(intent: ToggleRecordingIntent()) {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [
                                        Color(red: 111 / 255, green: 83 / 255, blue: 253 / 255),
                                        Color(red: 94 / 255, green: 92 / 255, blue: 230 / 255)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Image(systemName: context.state.isPaused ? "play.fill" : "pause.fill")
                                        .foregroundColor(.white)
                                        .font(.headline)
                                )
                        }
                        .buttonStyle(.plain)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(context.attributes.title)
                                .font(.subheadline)
                                .foregroundColor(.white)

                            TimerView(
                                duration: context.state.duration,
                                isPaused: context.state.isPaused,
                                color: Color.white.opacity(0.7)
                            )
                            .font(.body)
                            .multilineTextAlignment(.leading)
                        }
                    }
                }

                // 다이내믹 아일랜드 확장형 (오른쪽)
                DynamicIslandExpandedRegion(.trailing) {
                    AudioMeterView(
                        barCount: 17,
                        amplitude: Double(context.state.amplitude),
                        isPaused: context.state.isPaused
                    )
                    .padding(.trailing, 8)
                    .frame(maxHeight: .infinity)
                }
            } compactLeading: {
                // 다이내믹 아일랜드 최소형 (왼쪽 버튼)
                Image(systemName: "waveform")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                    .foregroundStyle(LinearGradient(
                        colors: [
                            Color(red: 111 / 255, green: 83 / 255, blue: 253 / 255),
                            Color(red: 94 / 255, green: 92 / 255, blue: 230 / 255)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
            } compactTrailing: {
                // 다이내믹 아일랜드 최소형 (오른쪽 타이머)
                ZStack(alignment: .trailing) {
                    TimerView(
                        duration: context.state.duration,
                        isPaused: context.state.isPaused,
                        color: .white
                    )
                    .font(.caption.bold())
                }
                .frame(width: 38, height: 24)
                .clipped()
            } minimal: {
                // 다이내믹 아일랜드 독립형 최소 형태
                Button(intent: ToggleRecordingIntent()) {
                    Circle()
                        .fill(LinearGradient(
                            colors: [
                                Color(red: 111 / 255, green: 83 / 255, blue: 253 / 255),
                                Color(red: 94 / 255, green: 92 / 255, blue: 230 / 255)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 24, height: 24)
                        .overlay(
                            Image(systemName: context.state.isPaused ? "play.fill" : "pause.fill")
                                .foregroundColor(.white)
                                .font(.caption2.bold())
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct LockScreenView: View {
    let context: ActivityViewContext<RecordingActivityAttributes>

    var body: some View {
        HStack(spacing: 16) {
            Button(intent: ToggleRecordingIntent()) {
                Circle()
                    .fill(LinearGradient(
                        colors: [
                            Color(red: 111 / 255, green: 83 / 255, blue: 253 / 255),
                            Color(red: 94 / 255, green: 92 / 255, blue: 230 / 255)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: context.state.isPaused ? "play.fill" : "pause.fill")
                            .foregroundColor(.white)
                            .font(.title2.bold())
                    )
            }
            .buttonStyle(.plain)

            // 가운데: 녹음 타이틀 및 시작 날짜/시간
            VStack(alignment: .leading, spacing: 4) {
                Text(context.attributes.title)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(context.attributes.startDate)
                    .font(.caption)
                    .foregroundColor(Color.white.opacity(0.6))
            }

            Spacer()

            // 오른쪽: 실시간 타이머 및 오디오 미터
            VStack(alignment: .trailing) {
                TimerView(
                    duration: context.state.duration,
                    isPaused: context.state.isPaused,
                    color: .white
                )
                .multilineTextAlignment(.trailing)
                .font(.title.bold())
                Spacer()
                AudioMeterView(
                    barCount: 15,
                    amplitude: Double(context.state.amplitude),
                    isPaused: context.state.isPaused
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .activityBackgroundTint(Color(red: 22 / 255, green: 21 / 255, blue: 27 / 255).opacity(0.95))
    }
}

struct TimerView: View {
    let duration: TimeInterval
    let isPaused: Bool
    let color: Color

    var body: some View {
        if isPaused {
            Text(duration.durationString)
                .monospacedDigit()
                .foregroundColor(color)
                .multilineTextAlignment(.trailing)
        } else {
            // 시스템 타이머 연동 (과거 시작 시점으로부터 카운트업 진행)
            Text(Date(timeIntervalSinceNow: -duration), style: .timer)
                .monospacedDigit()
                .foregroundColor(color)
        }
    }
}
