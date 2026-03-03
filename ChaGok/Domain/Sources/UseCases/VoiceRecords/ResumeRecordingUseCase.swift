import Foundation

/// 녹음 재시작 유스케이스 프로토콜.
/// `PauseRecordingUseCase`로 일시 정지한 녹음을 재개할 때 사용합니다.
public protocol ResumeRecordingUseCase {
    /// 녹음을 재시작합니다.
    /// - Throws: 일시 정지된 녹음이 없거나, 재시작 처리 실패 시
    func execute() async throws
}

public struct DefaultResumeRecordingUseCase: ResumeRecordingUseCase {

    private let recordingRepository: VoiceRecordRepository

    public init(recordingRepository: VoiceRecordRepository) {
        self.recordingRepository = recordingRepository
    }

    public func execute() async throws {
        try await recordingRepository.resumeRecording()
    }
}
