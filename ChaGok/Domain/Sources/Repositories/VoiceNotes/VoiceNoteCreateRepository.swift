import Foundation

/// 음성 메모 생성만 담당하는 리포지토리 프로토콜 (ISP).
public protocol VoiceNoteCreateRepository: Sendable {
    /// 새로운 음성 메모를 생성합니다.
    /// - Parameter voiceRecord: 녹음 정보 (오디오 경로, 길이 등)
    /// - Returns: 저장된 음성 메모 엔티티
    /// - Throws: `VoiceNoteCreateRepositoryError.createFailed`
    func create(_ voiceRecord: VoiceRecord) async throws(VoiceNoteCreateRepositoryError) -> VoiceNote
}
