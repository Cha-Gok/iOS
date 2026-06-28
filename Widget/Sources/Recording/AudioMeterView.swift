import Foundation
import SwiftUI

/// Live Activity / Dynamic Island에서 현재 녹음이 진행 중임을 시각적으로 보여주는 오디오 미터 뷰입니다.
/// amplitude(0.0~1.0) 값을 기반으로 각 바의 높이를 결정합니다.
///
/// 디자인 특징:
/// - 중앙 바가 가장 높고, 양 끝은 dot(원) 형태로 짧습니다.
/// - 바마다 고유한 변동을 적용하여 유기적인 웨이브폼을 표현합니다.
/// - RoundedRectangle로 끝이 둥근 바를 표현합니다.
public struct AudioMeterView: View {
    let barCount: Int
    let amplitude: Double
    let isPaused: Bool
    let activeColor: Color

    public init(
        barCount: Int = 27,
        amplitude: Double,
        isPaused: Bool,
        activeColor: Color = Color(red: 111 / 255, green: 83 / 255, blue: 253 / 255)
    ) {
        self.barCount = barCount
        self.amplitude = amplitude
        self.isPaused = isPaused
        self.activeColor = activeColor
    }

    public var body: some View {
        HStack(alignment: .center, spacing: 2) {
            ForEach(0 ..< barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: barWidth / 2)
                    .fill(isPaused ? Color.white.opacity(0.3) : activeColor)
                    .frame(width: barWidth, height: barHeight(for: index))
            }
        }
    }

    private var barWidth: CGFloat { 3.0 }

    private func barHeight(for index: Int) -> CGFloat {
        let dotHeight: CGFloat = barWidth // 양 끝의 dot은 정사각형(원)
        let maxHeight: CGFloat = 22.0

        guard !isPaused else {
            return dotHeight
        }

        let clampedAmplitude = min(max(amplitude, 0.0), 1.0)

        // ──────────────────────────────────────────────
        // 시각적 amplitude 보정
        // AVAudioRecorder의 dB→선형 변환 결과는 일반 음성에서 0.01~0.1 수준으로 매우 작습니다.
        // pow(x, 0.3) 곡선을 적용하여 작은 값을 시각적으로 증폭합니다.
        // 예) 0.01 → 0.25,  0.05 → 0.42,  0.1 → 0.50,  0.3 → 0.67,  1.0 → 1.0
        // ──────────────────────────────────────────────
        let boostedAmplitude = pow(clampedAmplitude, 0.3)

        // 중앙에서의 거리를 0.0(중앙) ~ 1.0(양 끝)으로 정규화
        let midIndex = Double(barCount - 1) / 2.0
        let distanceFromCenter = abs(Double(index) - midIndex)
        let normalizedDistance = midIndex > 0 ? distanceFromCenter / midIndex : 0.0

        // 중앙 가중치: 중앙(1.0) → 양 끝(0.0)
        // pow를 사용하여 양 끝에서 급격히 낮아지는 곡선 적용
        let centerWeight = pow(1.0 - normalizedDistance, 1.5)

        // 바마다 고유한 변동 패턴 (index 기반 의사 랜덤)
        let seed = Double(index * 13 + 5)
        let variation = sin(seed) * 0.5 + 0.5 // 0.0 ~ 1.0
        let jitter = 0.6 + variation * 0.8      // 0.6 ~ 1.4

        // 최종 높이: boostedAmplitude × centerWeight × jitter로 유기적 변화
        let targetHeight = dotHeight + (maxHeight - dotHeight) * boostedAmplitude * centerWeight * jitter

        return max(dotHeight, min(maxHeight, targetHeight))
    }
}

/// Live Activity / recording UI에 적합한 재사용 가능한 오디오 미터 컴포넌트입니다.
/// level 값에 따라 각 바의 높이가 랜덤하게 변하며, 자연스럽게 애니메이션됩니다.
public struct LiveAudioMeter: View {
    private let level: CGFloat
    private let barCount: Int
    private let maxHeight: CGFloat
    private let minHeight: CGFloat

    @State private var heights: [CGFloat] = []

    public init(
        level: CGFloat,
        barCount: Int = 7,
        maxHeight: CGFloat = 24,
        minHeight: CGFloat = 4
    ) {
        self.level = level
        self.barCount = max(1, barCount)
        self.maxHeight = max(minHeight, maxHeight)
        self.minHeight = max(1, minHeight)
    }

    public var body: some View {
        HStack(alignment: .center, spacing: 2) {
            ForEach(0 ..< barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 3, height: barHeight(for: index))
            }
        }
        .onAppear {
            refreshHeights(animated: false)
        }
        .onChange(of: level) { _, _ in
            refreshHeights(animated: true)
        }
        .onChange(of: barCount) { _, _ in
            refreshHeights(animated: false)
        }
        .onReceive(Timer.publish(every: 0.16, tolerance: 0.05, on: .main, in: .common).autoconnect()) { _ in
            refreshHeights(animated: true)
        }
    }

    private func barHeight(for index: Int) -> CGFloat {
        guard heights.indices.contains(index) else {
            return Self.makeHeight(
                for: index,
                barCount: barCount,
                level: level,
                maxHeight: maxHeight,
                minHeight: minHeight
            )
        }

        return heights[index]
    }

    private func refreshHeights(animated: Bool) {
        let nextHeights = (0 ..< barCount).map { index in
            Self.makeHeight(
                for: index,
                barCount: barCount,
                level: level,
                maxHeight: maxHeight,
                minHeight: minHeight
            )
        }

        if animated {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                heights = nextHeights
            }
        } else {
            heights = nextHeights
        }
    }

    static func makeHeight(
        for index: Int,
        barCount: Int,
        level: CGFloat,
        maxHeight: CGFloat,
        minHeight: CGFloat
    ) -> CGFloat {
        let normalizedLevel = min(max(level, 0.0), 1.0)
        let amplitudeLimit = minHeight + (maxHeight - minHeight) * normalizedLevel
        let availableRange = max(0.0, amplitudeLimit - minHeight)
        let variation = CGFloat(index % 5 + 1) / 5.0
        let randomFactor = CGFloat.random(in: 0.3 ... 1.0) * (0.65 + variation * 0.35)
        let rawHeight = minHeight + availableRange * randomFactor

        return min(maxHeight, max(minHeight, rawHeight))
    }
}
