import Core
import Foundation

/// 녹음 취소 유스케이스 프로토콜.
/// 진행 중인 녹음을 취소하고 임시 파일을 삭제합니다.
public protocol CancelRecordingUseCase: Sendable {
    /// 녹음을 취소합니다.
    /// - Throws: `CancelRecordingUseCaseError`
    func execute() async throws(CancelRecordingUseCaseError)
}

public struct DefaultCancelRecordingUseCase: CancelRecordingUseCase {
    private let recordingRepository: VoiceRecordRepository

    public init(recordingRepository: VoiceRecordRepository) {
        self.recordingRepository = recordingRepository
    }

    public func execute() async throws(CancelRecordingUseCaseError) {
        if Task.isCancelled { throw .cancelled }

        do {
            try await recordingRepository.cancelRecording()
        } catch {
            AppLogger.error(error)
            throw CancelRecordingUseCaseError(error)
        }
    }
}
