import Foundation

/// 음성 메모 조회(목록/단건) 리포지토리 프로토콜.
public protocol VoiceNoteFetchRepository: Sendable {
    /// 기본 폴더의 모든 음성 메모를 조회합니다.
    /// - Returns: 기본 폴더에 저장된 음성 메모 배열
    /// - Throws: `VoiceNoteFetchRepositoryError.defaultFolderNotFound`, `.fetchAllFailed`
    func fetchAllFromDefaultFolder() async throws(VoiceNoteFetchRepositoryError) -> [VoiceNote]

    /// 특정 폴더의 모든 음성 메모를 조회합니다.
    /// - Parameter folderID: 조회할 폴더의 ID
    /// - Returns: 조회된 음성 메모 배열
    /// - Throws: `VoiceNoteFetchRepositoryError.fetchAllFailed`
    func fetchAll(folderID: UUID) async throws(VoiceNoteFetchRepositoryError) -> [VoiceNote]

    /// 특정 음성 메모를 조회합니다.
    /// - Parameter id: 조회할 음성 메모의 ID
    /// - Returns: 조회된 음성 메모 엔티티
    /// - Throws: `VoiceNoteFetchRepositoryError.recordNotFound`, `VoiceNoteFetchRepositoryError.fetchFailed`
    func fetch(byId id: UUID) async throws(VoiceNoteFetchRepositoryError) -> VoiceNote

    /// 전체 폴더에서 최근 생성된 음성 메모를 조회합니다. (deletedAt이 없는 항목만, 생성일 내림차순)
    /// - Parameter limit: 가져올 최대 개수
    /// - Returns: 최근 생성된 음성 메모 배열
    /// - Throws: `VoiceNoteFetchRepositoryError.fetchRecentFailed`
    func fetchRecent(limit: Int) async throws(VoiceNoteFetchRepositoryError) -> [VoiceNote]
}
