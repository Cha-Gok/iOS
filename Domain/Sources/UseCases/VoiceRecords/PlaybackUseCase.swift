import Core
import Foundation

/// 재생 통합 유스케이스 프로토콜.
/// 오디오 재생의 준비, 재생, 일시정지, 탐색, 정지를 하나의 인터페이스로 제공합니다.
@MainActor
public protocol PlaybackUseCase: Sendable {
    /// 오디오 재생을 준비하고 재생 상태 스트림을 반환합니다.
    /// - Parameter audioFilePath: 재생할 오디오 파일 경로
    /// - Returns: 재생 상태 스트림
    /// - Throws: `PlaybackUseCaseError`
    func prepare(audioFilePath: String) throws(PlaybackUseCaseError) -> AsyncStream<AudioPlaybackState>

    /// 오디오 재생을 시작합니다.
    /// - Throws: `PlaybackUseCaseError`
    func play() throws(PlaybackUseCaseError)

    /// 오디오 재생을 일시정지합니다.
    /// - Throws: `PlaybackUseCaseError`
    func pause() throws(PlaybackUseCaseError)

    /// 오디오 재생 위치를 이동합니다.
    /// - Parameter time: 이동할 시간
    /// - Throws: `PlaybackUseCaseError`
    func seek(to time: TimeInterval) throws(PlaybackUseCaseError)

    /// 오디오 재생을 정지합니다.
    /// - Throws: `PlaybackUseCaseError`
    func stop() throws(PlaybackUseCaseError)
}

@MainActor
public struct DefaultPlaybackUseCase: PlaybackUseCase {
    private let repository: VoiceRecordPlaybackRepository

    public init(repository: VoiceRecordPlaybackRepository) {
        self.repository = repository
    }

    public func prepare(audioFilePath: String) throws(PlaybackUseCaseError) -> AsyncStream<AudioPlaybackState> {
        do {
            return try repository.prepare(audioFilePath: audioFilePath)
        } catch {
            AppLogger.error(error)
            throw PlaybackUseCaseError(error)
        }
    }

    public func play() throws(PlaybackUseCaseError) {
        do {
            try repository.play()
        } catch {
            AppLogger.error(error)
            throw PlaybackUseCaseError(error)
        }
    }

    public func pause() throws(PlaybackUseCaseError) {
        do {
            try repository.pause()
        } catch {
            AppLogger.error(error)
            throw PlaybackUseCaseError(error)
        }
    }

    public func seek(to time: TimeInterval) throws(PlaybackUseCaseError) {
        do {
            try repository.seek(to: time)
        } catch {
            AppLogger.error(error)
            throw PlaybackUseCaseError(error)
        }
    }

    public func stop() throws(PlaybackUseCaseError) {
        do {
            try repository.stop()
        } catch {
            AppLogger.error(error)
            throw PlaybackUseCaseError(error)
        }
    }
}
