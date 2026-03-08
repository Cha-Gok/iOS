import Foundation

public protocol VoiceRecordRepository: Sendable {
    /// 녹음(마이크) 권한이 허용되어 있는지 확인합니다. 미허용 시 요청 후 거부되면 throw.
    /// - Throws: `VoiceRecordRepositoryError.permissionDenied`
    func checkRecordingPermission() async throws(VoiceRecordRepositoryError)

    /// 녹음을 시작하고, 실시간 파형 데이터 스트림을 반환합니다.
    /// - Returns: 녹음 중 생성되는 파형 스트림.
    /// - Throws: `VoiceRecordRepositoryError.startFailed`
    func startRecording() async throws(VoiceRecordRepositoryError) -> AsyncStream<Waveform>

    /// 진행 중인 녹음을 일시 정지합니다.
    /// - Throws: `VoiceRecordRepositoryError.notRecording`, `VoiceRecordRepositoryError.pauseFailed`
    func pauseRecording() async throws(VoiceRecordRepositoryError)

    /// 일시 정지된 녹음을 다시 이어서 녹음합니다.
    /// - Throws: `VoiceRecordRepositoryError.notPaused`, `VoiceRecordRepositoryError.resumeFailed`
    func resumeRecording() async throws(VoiceRecordRepositoryError)

    /// 녹음을 종료하고 저장한 뒤, 저장된 녹음 정보를 반환합니다.
    /// - Returns: 저장된 녹음 엔티티
    /// - Throws: `VoiceRecordRepositoryError.notRecording`, `VoiceRecordRepositoryError.finishFailed`, `VoiceRecordRepositoryError.encodingFailed`
    func finishRecording() async throws(VoiceRecordRepositoryError) -> VoiceRecord
}
