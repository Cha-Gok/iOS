import Core
import Foundation

/// 녹음 일시정지 유스케이스 프로토콜.
/// 이미 시작된 녹음을 일시 정지할 때 사용합니다. 재시작은 `ResumeRecordingUseCase`로 합니다.
public protocol PauseRecordingUseCase {
    /// 녹음을 일시 정지합니다.
    /// - Throws: `VoiceRecordUseCaseError` (녹음 진행 중 아님, 일시정지 실패)
    func execute() async throws(VoiceRecordUseCaseError)
}

public struct DefaultPauseRecordingUseCase: PauseRecordingUseCase {

    private let recordingRepository: VoiceRecordRepository

    public init(recordingRepository: VoiceRecordRepository) {
        self.recordingRepository = recordingRepository
    }

    public func execute() async throws(VoiceRecordUseCaseError) {
        do {
            try Task.checkCancellation()
            try await recordingRepository.pauseRecording()
        } catch is CancellationError {
            let useCaseError = VoiceRecordUseCaseError.cancelled
            AppLogger.error(useCaseError)
            throw useCaseError
        } catch let error as VoiceRecordRepositoryError {
            AppLogger.error(error)
            throw mapFromRepository(error)
        } catch {
            let useCaseError = VoiceRecordUseCaseError.unknown(error)
            AppLogger.error(useCaseError)
            throw useCaseError
        }
    }

    private func mapFromRepository(_ error: VoiceRecordRepositoryError) -> VoiceRecordUseCaseError {
        switch error {
        case .notRecording: return .notRecording
        case .pauseFailed: return .pauseFailed
        case .cancelled: return .cancelled
        case .permissionDenied, .startFailed, .notPaused, .resumeFailed, .finishFailed, .encodingFailed:
            return .unknown(error)
        case .unknown(let error): return .unknown(error)
        }
    }
}
