import Core
import Foundation

/// 녹음 일시정지 유스케이스 프로토콜.
/// 이미 시작된 녹음을 일시 정지할 때 사용합니다. 재시작은 `ResumeRecordingUseCase`로 합니다.
public protocol PauseRecordingUseCase: Sendable {
    /// 녹음을 일시 정지합니다.
    /// - Throws: `PauseRecordingUseCaseError` (녹음 진행 중 아님, 일시정지 실패)
    func execute() async throws(PauseRecordingUseCaseError)
}

public struct DefaultPauseRecordingUseCase: PauseRecordingUseCase {
    private let recordingRepository: VoiceRecordRepository

    public init(recordingRepository: VoiceRecordRepository) {
        self.recordingRepository = recordingRepository
    }

    public func execute() async throws(PauseRecordingUseCaseError) {
        if Task.isCancelled { throw .cancelled }

        do {
            try await recordingRepository.pauseRecording()
        } catch {
            AppLogger.error(error)
            throw PauseRecordingUseCaseError(error)
        }
    }
}
