import Foundation

/// 녹음 일시정지 유스케이스 프로토콜.
/// 이미 시작된 녹음을 일시 정지할 때 사용합니다. 재시작은 `ResumeRecordingUseCase`로 합니다.
public protocol PauseRecordingUseCase {
    /// 녹음을 일시 정지합니다.
    /// - Throws: 녹음이 진행 중이 아니거나, 일시정지 처리 실패 시
    func execute() async throws
}

public struct DefaultPauseRecordingUseCase: PauseRecordingUseCase {

    private let recordingRepository: VoiceRecordRepository

    public init(recordingRepository: VoiceRecordRepository) {
        self.recordingRepository = recordingRepository
    }

    public func execute() async throws {
        try await recordingRepository.pauseRecording()
    }
}
