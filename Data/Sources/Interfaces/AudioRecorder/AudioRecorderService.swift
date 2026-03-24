import Domain

/// 오디오 녹음 인프라 서비스 프로토콜
public protocol AudioRecorderService: Sendable {
    /// 녹음을 시작하고 실시간 파형 데이터 스트림을 반환합니다.
    /// - Throws: `AudioRecorderServiceError` 엔진 시작 실패 시
    func startRecording() async throws(AudioRecorderServiceError) -> AsyncStream<Waveform>

    /// 진행 중인 녹음을 일시 정지합니다.
    /// - Throws: `AudioRecorderServiceError` 녹음 상태가 아니거나 일시 정지 실패 시
    func pauseRecording() async throws(AudioRecorderServiceError)

    /// 일시 정지된 녹음을 다시 시작합니다.
    /// - Throws: `AudioRecorderServiceError` 일시 정지 상태가 아니거나 재시작 실패 시
    func resumeRecording() async throws(AudioRecorderServiceError)

    /// 진행 중인 녹음을 종료하고 저장된 오디오 정보를 반환합니다.
    /// - Returns: 저장된 녹음 오디오 정보
    /// - Throws: `AudioRecorderServiceError` 녹음 상태가 아니거나 저장/인코딩 실패 시
    func finishRecording() async throws(AudioRecorderServiceError) -> RecordedAudio
}
