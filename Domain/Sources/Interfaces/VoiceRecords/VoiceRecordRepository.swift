import Foundation

/// 예약, 설정, 오디오 녹음 및 관련 마이크 권한을 관리하는 리포지토리 프로토콜.
public protocol VoiceRecordRepository: Sendable {
    /// 마이크 권한이 허용되어 있는지 확인합니다.
    /// - Returns: 현재 마이크 권한 상태.
    func checkMicrophonePermission() -> PermissionStatus

    /// 마이크 권한을 요청합니다.
    /// - Returns: 요청 결과 권한 상태.
    /// - Throws: `VoiceRecordRepositoryError.cancelled` 등
    func requestMicrophonePermission() async throws(VoiceRecordRepositoryError) -> PermissionStatus

    /// 녹음을 시작하고, 실시간 파형 데이터 스트림을 반환합니다.
    /// - Returns: 녹음 중 생성되는 파형 스트림.
    /// - Throws: `VoiceRecordRepositoryError.alreadyRecording`, `VoiceRecordRepositoryError.startFailed`
    func startRecording() async throws(VoiceRecordRepositoryError) -> AsyncStream<Waveform>

    /// 진행 중인 녹음을 일시 정지합니다.
    /// - Throws: `VoiceRecordRepositoryError.notRecording`, `VoiceRecordRepositoryError.pauseFailed`
    func pauseRecording() async throws(VoiceRecordRepositoryError)

    /// 일시 정지된 녹음을 다시 이어서 녹음합니다.
    /// - Throws: `VoiceRecordRepositoryError.notPaused`, `VoiceRecordRepositoryError.resumeFailed`
    func resumeRecording() async throws(VoiceRecordRepositoryError)

    /// 녹음을 종료하고 저장한 뒤, 저장된 녹음 정보를 반환합니다.
    /// - Returns: 저장된 녹음 엔티티
    /// - Throws: `VoiceRecordRepositoryError.notRecording`, `VoiceRecordRepositoryError.finishFailed`,
    /// `VoiceRecordRepositoryError.encodingFailed`
    func finishRecording() async throws(VoiceRecordRepositoryError) -> VoiceRecord

    /// 진행 중인 녹음을 취소하고 임시 파일을 삭제합니다.
    /// - Throws: `VoiceRecordRepositoryError.cancelled`
    func cancelRecording() async throws(VoiceRecordRepositoryError)
}
