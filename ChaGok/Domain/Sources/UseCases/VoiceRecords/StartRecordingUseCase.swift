import Foundation

/// 녹음 시작 유스케이스 프로토콜.
/// 호출 시 마이크 권한을 확인하고, 허용된 경우 녹음을 시작한 뒤 파형(Waveform) 스트림을 반환합니다.
public protocol StartRecordingUseCase {
    /// 녹음을 시작하고 실시간 파형 데이터 스트림을 반환합니다.
    /// - Returns: 녹음 중 생성되는 파형 샘플 스트림. 호출부에서 `for await`로 소비하여 UI에 파형을 그릴 수 있습니다.
    /// - Throws: 권한 거부 시 또는 녹음 시작 실패 시
    func execute() async throws -> AsyncStream<Waveform>
}

public struct DefaultStartRecordingUseCase: StartRecordingUseCase {

    private let recordingRepository: VoiceRecordRepository

    public init(recordingRepository: VoiceRecordRepository) {
        self.recordingRepository = recordingRepository
    }

    public func execute() async throws -> AsyncStream<Waveform> {
        // 1. 녹음 권한 확인 (미허용 시 throw)
        try await recordingRepository.checkRecordingPermission()

        // 2. 녹음 시작 후 파형 스트림 반환
        return try await recordingRepository.startRecording()
    }
}
