import Foundation

/// 음성 메모 업데이트만 담당하는 리포지토리 프로토콜 (ISP).
public protocol VoiceNoteUpdateRepository: Sendable {
    /// 음성 메모 정보를 업데이트합니다.
    /// - Parameter voiceNote: 업데이트할 음성 메모 엔티티
    /// - Returns: 업데이트된 음성 메모 엔티티
    /// - Throws: `VoiceNoteRepositoryError.updateFailed`
    func update(_ voiceNote: VoiceNote) async throws(VoiceNoteRepositoryError) -> VoiceNote
}
