import Foundation

public protocol VoiceRecordFinishRepository: Sendable {
    /// 녹음을 종료하고 저장한 뒤, 저장된 녹음 정보를 반환합니다.
    /// - Returns: 저장된 녹음 엔티티
    /// - Throws: `VoiceRecordFinishRepositoryError.notRecording`, `VoiceRecordFinishRepositoryError.finishFailed`,
    /// `VoiceRecordFinishRepositoryError.encodingFailed`
    func finishRecording() async throws(VoiceRecordFinishRepositoryError) -> VoiceRecord
}
