import Core
import Foundation

/// 녹음 완료 유스케이스 프로토콜.
/// 녹음을 종료하고, 저장된 오디오 파일 경로·길이 등이 담긴 `VoiceRecord`를 반환합니다.
public protocol FinishRecordingUseCase {
    /// 녹음을 완료하고 저장된 녹음 정보를 반환합니다.
    /// - Returns: 저장된 녹음 엔티티 (id, 생성일시, 오디오 파일 경로, 길이 등)
    /// - Throws: `VoiceRecordUseCaseError` (녹음 진행 중 아님, 저장·인코딩 실패)
    func execute() async throws(VoiceRecordUseCaseError) -> VoiceRecord
}

public struct DefaultFinishRecordingUseCase: FinishRecordingUseCase {

    private let recordingRepository: VoiceRecordRepository

    public init(recordingRepository: VoiceRecordRepository) {
        self.recordingRepository = recordingRepository
    }

    public func execute() async throws(VoiceRecordUseCaseError) -> VoiceRecord {
        do {
            try Task.checkCancellation()
            return try await recordingRepository.finishRecording()
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
        case .finishFailed: return .finishFailed
        case .encodingFailed: return .encodingFailed
        case .cancelled: return .cancelled
        case .permissionDenied, .startFailed, .notPaused, .pauseFailed, .resumeFailed:
            return .unknown(error)
        case .unknown(let error): return .unknown(error)
        }
    }
}
