import Foundation

/// 음성 메모(VoiceNote) 엔티티의 CRUD 및 오디오 분석을 담당하는 리포지토리 프로토콜.
public protocol VoiceNoteRepository: Sendable {
    /// 새로운 음성 메모를 생성합니다.
    /// - Parameter voiceNote: 생성할 음성 메모 엔티티
    /// - Returns: 저장된 음성 메모 엔티티
    /// - Throws: 생성 실패 시
    func create(_ voiceRecord: VoiceRecord) async throws -> VoiceNote

    /// 특정 폴더의 모든 음성 메모를 조회합니다.
    /// - Parameter folderID: 조회할 폴더의 ID
    /// - Returns: 조회된 음성 메모 배열
    /// - Throws: 조회 실패 시
    func fetchAll(folderID: UUID) async throws -> [VoiceNote]

    /// 특정 음성 메모를 조회합니다.
    /// - Parameter id: 조회할 음성 메모의 ID
    /// - Returns: 조회된 음성 메모 엔티티
    /// - Throws: 조회 실패 시
    func fetch(byId id: UUID) async throws -> VoiceNote

    /// 음성 메모 정보를 업데이트합니다.
    /// - Parameter voiceNote: 업데이트할 음성 메모 엔티티
    /// - Returns: 업데이트된 음성 메모 엔티티
    /// - Throws: 업데이트 실패 시
    func update(_ voiceNote: VoiceNote) async throws -> VoiceNote

    /// 특정 음성 메모를 삭제합니다.
    /// - Parameter id: 삭제할 음성 메모의 ID
    /// - Throws: 삭제 실패 시
    func delete(byId id: UUID) async throws
}
