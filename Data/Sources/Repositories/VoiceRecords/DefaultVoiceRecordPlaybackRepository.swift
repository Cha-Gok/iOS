import AVFoundation
import Core
import Domain
import Foundation

@MainActor
public final class DefaultVoiceRecordPlaybackRepository: NSObject, VoiceRecordPlaybackRepository {
    private let storageService: any StorageService

    // AudioPlaybackPlayerService에서 가져온 프로퍼티들
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

    public init(storageService: any StorageService) {
        self.storageService = storageService
        super.init()
    }

    // MARK: - VoiceRecordPlaybackRepository

    public func prepare(audioFilePath: String) throws(VoiceRecordPlaybackRepositoryError)
        -> AsyncStream<AudioPlaybackState>
    {
        let absoluteURL = storageService.absoluteURL(for: audioFilePath)

        // 이전 세션 정리
        player?.stop()
        stopProgressTask()
        player?.delegate = nil
        player = nil
        deactivateSessionIfNeeded()

        let player: AVAudioPlayer
        do {
            player = try AVAudioPlayer(contentsOf: absoluteURL)
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

    public func play() throws(VoiceRecordPlaybackRepositoryError) {
        guard let player else { throw .notPrepared }

        if player.currentTime >= player.duration {
            player.currentTime = 0
        }

        do {
            try activateSession()
        } catch {
            throw .playFailed
        }

        guard player.play() else { throw .playFailed }

        startProgressTask()
        updateState(status: .playing, currentTime: player.currentTime, duration: player.duration)
    }

    public func pause() throws(VoiceRecordPlaybackRepositoryError) {
        guard let player else { throw .notPrepared }
        guard player.isPlaying else { throw .pauseFailed }

        player.pause()
        stopProgressTask()
        updateState(status: .paused, currentTime: player.currentTime, duration: player.duration)
    }

    public func seek(to time: TimeInterval) throws(VoiceRecordPlaybackRepositoryError) {
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

    public func stop() throws(VoiceRecordPlaybackRepositoryError) {
        player?.stop()
        player?.currentTime = 0
        stopProgressTask()
        player?.delegate = nil
        player = nil
        updateState(status: .idle, currentTime: 0, duration: duration)
        deactivateSessionIfNeeded()
    }
}

// MARK: - AVAudioPlayerDelegate

extension DefaultVoiceRecordPlaybackRepository: AVAudioPlayerDelegate {
    public nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        let duration = player.duration
        Task { @MainActor [weak self] in
            guard let self, flag else { return }
            stopProgressTask()
            updateState(status: .finished, currentTime: duration, duration: duration)
            deactivateSessionIfNeeded()
        }
    }

    public nonisolated func audioPlayerBeginInterruption(_ player: AVAudioPlayer) {
        Task { @MainActor [weak self] in
            guard let self, let player = self.player else { return }
            player.pause()
            stopProgressTask()
            updateState(status: .paused, currentTime: player.currentTime, duration: player.duration)
        }
    }

    public nonisolated func audioPlayerEndInterruption(_ player: AVAudioPlayer, withOptions flags: Int) {
        let shouldResume = AVAudioSession.InterruptionOptions(rawValue: UInt(flags)).contains(.shouldResume)
        Task { @MainActor [weak self] in
            guard let self, let player = self.player else { return }
            if shouldResume {
                try? activateSession()
                _ = player.play()
                startProgressTask()
                updateState(status: .playing, currentTime: player.currentTime, duration: player.duration)
            } else {
                updateState(status: .paused, currentTime: player.currentTime, duration: player.duration)
            }
        }
    }
}

// MARK: - Private Helpers

private extension DefaultVoiceRecordPlaybackRepository {
    func activateSession() throws {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
            isSessionActive = true
        } catch {
            throw error
        }
    }

    func deactivateSessionIfNeeded() {
        guard isSessionActive else { return }
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            isSessionActive = false
        } catch {
            AppLogger.error(error)
        }
    }

    func startProgressTask() {
        progressTask?.cancel()
        progressTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self, let player else { return }
                if player.isPlaying {
                    updateState(status: .playing, currentTime: player.currentTime, duration: player.duration)
                }
                try? await Task.sleep(nanoseconds: Policy.playbackProgressUpdateInterval)
            }
        }
    }

    func stopProgressTask() {
        progressTask?.cancel()
        progressTask = nil
    }

    func updateState(status: AudioPlaybackState.Status, currentTime: TimeInterval, duration: TimeInterval) {
        playbackStatus = status
        playbackContinuation.yield(AudioPlaybackState(status: status, currentTime: currentTime, duration: duration))
    }
}
