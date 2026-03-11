import Foundation

/// 특정 폴더의 음성 메모 목록 조회만 담당하는 리포지토리 프로토콜 (ISP).
public protocol VoiceNoteFetchAllRepository: Sendable {
    /// 특정 폴더의 모든 음성 메모를 조회합니다.
    /// - Parameter folderID: 조회할 폴더의 ID
    /// - Returns: 조회된 음성 메모 배열
    /// - Throws: `VoiceNoteRepositoryError.fetchAllFailed`
    func fetchAll(folderID: UUID) async throws(VoiceNoteRepositoryError) -> [VoiceNote]
}
