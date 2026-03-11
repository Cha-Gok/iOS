import Foundation

/// 음성 메모 삭제만 담당하는 리포지토리 프로토콜 (ISP).
public protocol VoiceNoteDeleteRepository: Sendable {
    /// 특정 음성 메모를 삭제합니다.
    /// - Parameter id: 삭제할 음성 메모의 ID
    /// - Throws: `VoiceNoteRepositoryError.deleteFailed`
    func delete(byId id: UUID) async throws(VoiceNoteRepositoryError)
}
