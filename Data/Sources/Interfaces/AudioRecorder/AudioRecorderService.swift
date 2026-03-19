import Domain

/// 오디오 녹음 인프라 서비스 프로토콜
public protocol AudioRecorderService: Sendable {
    /// 녹음을 시작하고 실시간 파형 데이터 스트림을 반환합니다.
    /// - Throws: 엔진 시작 실패 시 에러
    func startRecording() async throws -> AsyncStream<Waveform>
}
