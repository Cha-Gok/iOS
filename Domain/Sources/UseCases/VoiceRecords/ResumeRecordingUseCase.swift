import Core
import Foundation

/// 녹음 재시작 유스케이스 프로토콜.
/// `PauseRecordingUseCase`로 일시 정지한 녹음을 재개할 때 사용합니다.
public protocol ResumeRecordingUseCase: Sendable {
    /// 녹음을 재시작합니다.
    /// - Throws: `ResumeRecordingUseCaseError` (일시 정지된 녹음 없음, 재시작 실패)
    func execute() async throws(ResumeRecordingUseCaseError)
}

public struct DefaultResumeRecordingUseCase: ResumeRecordingUseCase {
    private let recordingRepository: VoiceRecordResumeRepository

    public init(recordingRepository: VoiceRecordResumeRepository) {
        self.recordingRepository = recordingRepository
    }

    public func execute() async throws(ResumeRecordingUseCaseError) {
        if Task.isCancelled { throw .cancelled }

        do {
            try await recordingRepository.resumeRecording()
        } catch {
            AppLogger.error(error)
            throw ResumeRecordingUseCaseError(error)
        }
    }
}

fileprivate extension ResumeRecordingUseCaseError {
    init(_ error: VoiceRecordResumeRepositoryError) {
        switch error {
        case .notPaused: self = .notPaused
        case .resumeFailed: self = .resumeFailed
        case .cancelled: self = .cancelled
        case .unknown(let error): self = .unknown(error)
        }
    }
}
