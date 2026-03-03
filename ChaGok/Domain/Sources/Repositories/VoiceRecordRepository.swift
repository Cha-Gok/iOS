import Foundation

public protocol VoiceRecordRepository: Sendable {
    /// 녹음(마이크) 권한이 허용되어 있는지 확인합니다. 미허용 시 요청 후 거부되면 throw.
    /// - Throws: 권한 거부 시
    func checkRecordingPermission() async throws

    /// 녹음을 시작하고, 실시간 파형 데이터 스트림을 반환합니다.
    /// - Returns: 녹음 중 생성되는 파형 스트림.
    /// - Throws: 녹음 시작 실패 시
    func startRecording() async throws -> AsyncStream<Waveform>

    /// 진행 중인 녹음을 일시 정지합니다.
    /// - Throws: 녹음이 진행 중이 아니거나 일시정지 실패 시
    func pauseRecording() async throws

    /// 일시 정지된 녹음을 다시 이어서 녹음합니다.
    /// - Throws: 일시 정지된 녹음이 없거나 재시작 실패 시
    func resumeRecording() async throws

    /// 녹음을 종료하고 저장한 뒤, 저장된 녹음 정보를 반환합니다.
    /// - Returns: 저장된 녹음 엔티티
    /// - Throws: 녹음이 진행 중이 아니거나 저장·인코딩 실패 시
    func finishRecording() async throws -> VoiceRecord
}
