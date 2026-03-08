import Core
import Foundation

/// 녹음 재시작 유스케이스 프로토콜.
/// `PauseRecordingUseCase`로 일시 정지한 녹음을 재개할 때 사용합니다.
public protocol ResumeRecordingUseCase {
    /// 녹음을 재시작합니다.
    /// - Throws: `VoiceRecordUseCaseError` (일시 정지된 녹음 없음, 재시작 실패)
    func execute() async throws(VoiceRecordUseCaseError)
}

public struct DefaultResumeRecordingUseCase: ResumeRecordingUseCase {

    private let recordingRepository: VoiceRecordRepository

    public init(recordingRepository: VoiceRecordRepository) {
        self.recordingRepository = recordingRepository
    }

    public func execute() async throws(VoiceRecordUseCaseError) {
        do {
            try Task.checkCancellation()
            try await recordingRepository.resumeRecording()
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
        case .notPaused: return .notPaused
        case .resumeFailed: return .resumeFailed
        case .cancelled: return .cancelled
        case .permissionDenied, .startFailed, .notRecording, .pauseFailed, .finishFailed,
            .encodingFailed:
            return .unknown(error)
        case .unknown(let error): return .unknown(error)
        }
    }
}
