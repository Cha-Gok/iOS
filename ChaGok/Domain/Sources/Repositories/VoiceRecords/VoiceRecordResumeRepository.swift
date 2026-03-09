import Foundation

public protocol VoiceRecordResumeRepository: Sendable {
    /// 일시 정지된 녹음을 다시 이어서 녹음합니다.
    /// - Throws: `VoiceRecordResumeRepositoryError.notPaused`, `VoiceRecordResumeRepositoryError.resumeFailed`
    func resumeRecording() async throws(VoiceRecordResumeRepositoryError)
}
