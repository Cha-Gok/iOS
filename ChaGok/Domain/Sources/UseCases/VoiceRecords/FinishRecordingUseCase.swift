import Foundation

/// 녹음 완료 유스케이스 프로토콜.
/// 녹음을 종료하고, 저장된 오디오 파일 경로·길이 등이 담긴 `VoiceRecord`를 반환합니다.
public protocol FinishRecordingUseCase {
    /// 녹음을 완료하고 저장된 녹음 정보를 반환합니다.
    /// - Returns: 저장된 녹음 엔티티 (id, 생성일시, 오디오 파일 경로, 길이 등)
    /// - Throws: 녹음이 진행 중이 아니거나, 저장·인코딩 실패 시
    func execute() async throws -> VoiceRecord
}

public struct DefaultFinishRecordingUseCase: FinishRecordingUseCase {

    private let recordingRepository: VoiceRecordRepository

    public init(recordingRepository: VoiceRecordRepository) {
        self.recordingRepository = recordingRepository
    }

    public func execute() async throws -> VoiceRecord {
        try await recordingRepository.finishRecording()
    }
}
