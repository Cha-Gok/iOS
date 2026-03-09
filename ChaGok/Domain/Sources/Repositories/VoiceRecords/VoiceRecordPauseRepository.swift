import Foundation

public protocol VoiceRecordPauseRepository: Sendable {
    /// 진행 중인 녹음을 일시 정지합니다.
    /// - Throws: `VoiceRecordPauseRepositoryError.notRecording`, `VoiceRecordPauseRepositoryError.pauseFailed`
    func pauseRecording() async throws(VoiceRecordPauseRepositoryError)
}
