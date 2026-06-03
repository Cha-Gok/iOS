import Foundation

/// 음성 메모 통합 리포지토리 프로토콜.
@MainActor
public protocol VoiceNoteRepository: Sendable {
    /// 음성 메모를 영속화합니다.
    func create(_ voiceNote: VoiceNote) throws(VoiceNoteRepositoryError) -> VoiceNote

    /// 음성 메모 정보를 업데이트합니다.
    func update(_ voiceNote: VoiceNote) throws(VoiceNoteRepositoryError) -> VoiceNote

    /// 특정 음성 메모를 조회합니다.
    func fetch(byId id: UUID) throws(VoiceNoteRepositoryError) -> VoiceNote

    /// ID로 음성 메모를 관찰합니다. 첫 emit은 현재 상태이며, 이후 변경 시 재emit됩니다.
    func observe(id: UUID) throws(VoiceNoteRepositoryError) -> AsyncStream<VoiceNote>

    /// 특정 폴더의 음성 메모 목록을 관찰합니다. 첫 emit은 현재 상태이며, 이후 변경 시 재emit됩니다.
    func observe(folderID: UUID) throws(VoiceNoteRepositoryError) -> AsyncStream<[VoiceNote]>

    /// 최근 생성된 음성 메모 목록을 관찰합니다. 첫 emit은 현재 상태이며, 이후 변경 시 재emit됩니다.
    func observeRecent(limit: Int) throws(VoiceNoteRepositoryError) -> AsyncStream<[VoiceNote]>

    /// 휴지통에 단독 삭제(folderID == trash.id AND deletedAt != nil)된 노트만 관찰합니다.
    /// 폴더 cascade 삭제 노트는 부모 폴더가 휴지통에 있는 것으로 표현되므로 본 query에 잡히지 않습니다.
    func observeTrashed() throws(VoiceNoteRepositoryError) -> AsyncStream<[VoiceNote]>

    /// 노트를 영구 삭제합니다.
    func delete(id: UUID) throws(VoiceNoteRepositoryError)
}
