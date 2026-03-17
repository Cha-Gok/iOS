import Foundation

public protocol VoiceRecordStartRepository: Sendable {
    /// 녹음을 시작하고, 실시간 파형 데이터 스트림을 반환합니다.
    /// - Returns: 녹음 중 생성되는 파형 스트림.
    /// - Throws: `VoiceRecordStartRepositoryError.startFailed`
    func startRecording() async throws(VoiceRecordStartRepositoryError) -> AsyncStream<Waveform>
}
