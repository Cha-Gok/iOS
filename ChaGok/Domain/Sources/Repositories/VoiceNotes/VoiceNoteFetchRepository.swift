import Foundation

/// 음성 메모 단건 조회만 담당하는 리포지토리 프로토콜 (ISP).
public protocol VoiceNoteFetchRepository: Sendable {
    /// 특정 음성 메모를 조회합니다.
    /// - Parameter id: 조회할 음성 메모의 ID
    /// - Returns: 조회된 음성 메모 엔티티
    /// - Throws: `VoiceNoteRepositoryError.recordNotFound`, `VoiceNoteRepositoryError.fetchFailed`
    func fetch(byId id: UUID) async throws(VoiceNoteRepositoryError) -> VoiceNote
}
