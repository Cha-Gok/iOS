import AVFoundation
import Core
import Domain
import Foundation

/// AVAudioPlayer 기반 오디오 재생 서비스.
///
/// `@MainActor`로 격리되어 별도 동기화 없이 상태를 안전하게 관리하며,
/// `AVAudioPlayerDelegate`를 직접 채택해 재생 완료·인터럽션 이벤트를 처리합니다.
/// 재생 상태 변화는 `playbackStream`을 통해 스트리밍됩니다.
@MainActor
public final class AudioPlaybackPlayerService: NSObject, AudioPlaybackService {
    private var player: AVAudioPlayer?
    private var progressTask: Task<Void, Never>?
    private var playbackStatus: AudioPlaybackState.Status = .idle
    private var duration: TimeInterval = 0
    private let _playback = AsyncStream<AudioPlaybackState>
        .makeStream(bufferingPolicy: .bufferingNewest(Policy.playbackStateStreamBufferLimit))
    private var isSessionActive = false

    private var playbackStream: AsyncStream<AudioPlaybackState> {
        _playback.stream
    }

    private var playbackContinuation: AsyncStream<AudioPlaybackState>.Continuation {
        _playback.continuation
    }

    /// 새 파일을 준비하고 재생 상태 스트림을 반환합니다.
    /// `AVAudioPlayer(contentsOf:)`를 사용해 메모리 맵핑 방식으로 효율적으로 파일을 로드합니다.
    public func preparePlayback(at fileURL: URL) throws(AudioPlaybackServiceError)
        -> AsyncStream<AudioPlaybackState>
    {
        // 이전 재생 세션 정리
        player?.stop()
        stopProgressTask()
        player?.delegate = nil
        player = nil
        deactivateSessionIfNeeded()

        let player: AVAudioPlayer
        do {
            player = try AVAudioPlayer(contentsOf: fileURL)
        } catch {
            AppLogger.error(error)
            throw .prepareFailed
        }

        player.delegate = self
        guard player.prepareToPlay() else { throw .prepareFailed }

        self.player = player
        duration = player.duration
        updateState(status: .idle, currentTime: 0, duration: player.duration)
        return playbackStream
    }

    public func play() throws(AudioPlaybackServiceError) {
        guard let player else { throw .notPrepared }

        // 끝까지 재생된 상태라면 처음부터 다시 시작
        if player.currentTime >= player.duration {
            player.currentTime = 0
        }

        try activateSession()
        guard player.play() else { throw .playFailed }

        startProgressTask()
        updateState(status: .playing, currentTime: player.currentTime, duration: player.duration)
    }

    public func pause() throws(AudioPlaybackServiceError) {
        guard let player else { throw .notPrepared }
        guard player.isPlaying else { throw .pauseFailed }

        player.pause()
        stopProgressTask()
        updateState(status: .paused, currentTime: player.currentTime, duration: player.duration)
    }

    public func seek(to time: TimeInterval) throws(AudioPlaybackServiceError) {
        guard let player else { throw .notPrepared }

        let clampedTime = min(max(0, time), player.duration)
        player.currentTime = clampedTime

        let status: AudioPlaybackState.Status = {
            if player.isPlaying { return .playing }
            if player.duration > 0, clampedTime >= player.duration { return .finished }
            if playbackStatus == .idle, clampedTime == 0 { return .idle }
            return .paused
        }()

        updateState(status: status, currentTime: clampedTime, duration: player.duration)
    }

    public func stop() throws(AudioPlaybackServiceError) {
        player?.stop()
        player?.currentTime = 0
        stopProgressTask()
        player?.delegate = nil
        player = nil
        // player 해제 후에도 duration을 유지해 UI가 총 길이를 표시할 수 있도록
        updateState(status: .idle, currentTime: 0, duration: duration)
        deactivateSessionIfNeeded()
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioPlaybackPlayerService: AVAudioPlayerDelegate {
    /// AVAudioPlayerDelegate 콜백은 nonisolated 컨텍스트에서 호출되므로
    /// Task를 통해 MainActor로 전환 후 처리
    public nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor [weak self] in self?.handlePlaybackFinished(successfully: flag) }
    }

    public nonisolated func audioPlayerBeginInterruption(_ player: AVAudioPlayer) {
        Task { @MainActor [weak self] in self?.handleInterruptionBegan() }
    }

    public nonisolated func audioPlayerEndInterruption(_ player: AVAudioPlayer, withOptions flags: Int) {
        let shouldResume = AVAudioSession.InterruptionOptions(rawValue: UInt(flags)).contains(.shouldResume)
        Task { @MainActor [weak self] in self?.handleInterruptionEnded(shouldResume: shouldResume) }
    }
}

// MARK: - Private

private extension AudioPlaybackPlayerService {
    func handlePlaybackFinished(successfully: Bool) {
        guard successfully, let player else { return }
        stopProgressTask()
        // currentTime을 duration과 동일하게 설정해 UI가 끝 위치를 표시하도록
        updateState(status: .finished, currentTime: player.duration, duration: player.duration)
        deactivateSessionIfNeeded()
    }

    func handleInterruptionBegan() {
        guard let player else { return }
        player.pause()
        stopProgressTask()
        updateState(status: .paused, currentTime: player.currentTime, duration: player.duration)
    }

    func handleInterruptionEnded(shouldResume: Bool) {
        guard let player else { return }
        if shouldResume {
            try? activateSession()
            _ = player.play()
            startProgressTask()
            updateState(status: .playing, currentTime: player.currentTime, duration: player.duration)
        } else {
            updateState(status: .paused, currentTime: player.currentTime, duration: player.duration)
        }
    }

    func activateSession() throws(AudioPlaybackServiceError) {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
            isSessionActive = true
        } catch {
            AppLogger.error(error)
            let code = AVAudioSession.ErrorCode(rawValue: (error as NSError).code)
            switch code {
            case .insufficientPriority: throw .sessionActivationFailed
            case .mediaServicesFailed: throw .mediaServicesFailed
            default: throw .unknown(error)
            }
        }
    }

    func deactivateSessionIfNeeded() {
        guard isSessionActive else { return }
        do {
            // 다른 앱(음악 등)이 오디오를 재개할 수 있도록 알림 옵션 포함
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            isSessionActive = false
        } catch {
            AppLogger.error(error)
        }
    }

    func startProgressTask() {
        progressTask?.cancel()
        progressTask = Task { [weak self] in await self?.streamProgress() }
    }

    /// 진행 중인 Task를 취소합니다.
    func stopProgressTask() {
        progressTask?.cancel()
        progressTask = nil
    }

    /// 재생 중 주기적으로 currentTime을 스트림에 방출
    func streamProgress() async {
        while !Task.isCancelled {
            guard let player else { return }
            if player.isPlaying {
                updateState(status: .playing, currentTime: player.currentTime, duration: player.duration)
            }
            try? await Task.sleep(nanoseconds: Policy.playbackProgressUpdateInterval)
        }
    }

    func updateState(status: AudioPlaybackState.Status, currentTime: TimeInterval, duration: TimeInterval) {
        playbackStatus = status
        playbackContinuation.yield(AudioPlaybackState(status: status, currentTime: currentTime, duration: duration))
    }
}
