import Foundation

public struct AudioPlaybackState: Sendable, Equatable {
    public enum Status: Sendable, Equatable {
        case idle
        case playing
        case paused
        case finished
    }

    public let status: Status
    public let currentTime: TimeInterval
    public let duration: TimeInterval

    public init(
        status: Status,
        currentTime: TimeInterval,
        duration: TimeInterval
    ) {
        self.status = status
        self.currentTime = currentTime
        self.duration = duration
    }
}
