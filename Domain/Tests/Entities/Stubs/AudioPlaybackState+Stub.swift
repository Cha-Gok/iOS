@testable import Domain
import Foundation

public extension AudioPlaybackState {
    static func stub(
        status: AudioPlaybackState.Status = .idle,
        currentTime: TimeInterval = 0,
        duration: TimeInterval = 60
    ) -> AudioPlaybackState {
        AudioPlaybackState(
            status: status,
            currentTime: currentTime,
            duration: duration
        )
    }
}
