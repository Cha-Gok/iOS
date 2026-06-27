import ActivityKit
import Foundation

public struct RecordingActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var duration: TimeInterval
        public var isPaused: Bool

        public init(duration: TimeInterval, isPaused: Bool) {
            self.duration = duration
            self.isPaused = isPaused
        }
    }

    public var title: String
    public var startDate: Date

    public init(title: String, startDate: Date) {
        self.title = title
        self.startDate = startDate
    }
}
