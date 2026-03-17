import Core
import Foundation

/// 녹음 완료 유스케이스 프로토콜.
/// 녹음을 종료하고, 저장된 오디오 파일 경로·길이 등이 담긴 `VoiceRecord`를 반환합니다.
public protocol FinishRecordingUseCase: Sendable {
    /// 녹음을 완료하고 저장된 녹음 정보를 반환합니다.
    /// - Returns: 저장된 녹음 엔티티 (id, 생성일시, 오디오 파일 경로, 길이 등)
    /// - Throws: `FinishRecordingUseCaseError` (녹음 진행 중 아님, 저장·인코딩 실패)
    func execute() async throws(FinishRecordingUseCaseError) -> VoiceRecord
}

public struct DefaultFinishRecordingUseCase: FinishRecordingUseCase {
    private let recordingRepository: VoiceRecordFinishRepository

    public init(recordingRepository: VoiceRecordFinishRepository) {
        self.recordingRepository = recordingRepository
    }

    public func execute() async throws(FinishRecordingUseCaseError) -> VoiceRecord {
        if Task.isCancelled { throw .cancelled }

        do {
            return try await recordingRepository.finishRecording()
        } catch {
            AppLogger.error(error)
            throw FinishRecordingUseCaseError(error)
        }
    }
}
