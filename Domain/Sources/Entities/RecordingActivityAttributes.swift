import ActivityKit
import Foundation

public struct RecordingActivityAttributes: ActivityAttributes, Sendable {
    public struct ContentState: Codable, Hashable, Sendable {
        public var duration: TimeInterval
        public var isPaused: Bool
        public var amplitude: Float

        public init(duration: TimeInterval, isPaused: Bool, amplitude: Float) {
            self.duration = duration
            self.isPaused = isPaused
            self.amplitude = amplitude
        }
    }

    public var startDate: String
    public var title: String

    public init(title: String, startDate: String) {
        self.title = title
        self.startDate = startDate
    }
}
