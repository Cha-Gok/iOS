import Foundation

/// 음성 메모 통합 리포지토리 프로토콜.
@MainActor
public protocol VoiceNoteRepository: Sendable {
    /// 새로운 음성 메모를 생성합니다.
    func create(_ voiceRecord: VoiceRecord) throws(VoiceNoteRepositoryError) -> VoiceNote

    /// 음성 메모 정보를 업데이트합니다.
    func update(_ voiceNote: VoiceNote) throws(VoiceNoteRepositoryError) -> VoiceNote

    /// 기본 폴더의 모든 음성 메모를 조회합니다.
    func fetchAllFromDefaultFolder() throws(VoiceNoteRepositoryError) -> [VoiceNote]

    /// 특정 폴더의 모든 음성 메모를 조회합니다.
    func fetchAll(folderID: UUID) throws(VoiceNoteRepositoryError) -> [VoiceNote]

    /// 특정 음성 메모를 조회합니다.
    func fetch(byId id: UUID) throws(VoiceNoteRepositoryError) -> VoiceNote

    /// 최근 생성된 음성 메모를 조회합니다.
    func fetchRecent(limit: Int) throws(VoiceNoteRepositoryError) -> [VoiceNote]

    /// ID로 음성 메모를 관찰합니다. 첫 emit은 현재 상태이며, 이후 변경 시 재emit됩니다.
    func observe(id: UUID) throws(VoiceNoteRepositoryError) -> AsyncStream<VoiceNote>
}
