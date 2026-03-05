import Foundation

/// 음성 메모 조회 유스케이스 프로토콜.
public protocol ReadVoiceNoteUseCase: Sendable {
    /// 특정 폴더의 모든 음성 메모를 조회합니다.
    /// - Parameter folderID: 조회할 폴더의 ID
    /// - Returns: 조회된 `VoiceNote` 배열
    /// - Throws: 조회 실패 시
    func execute(folderID: UUID) async throws -> [VoiceNote]

    /// 특정 음성 메모를 조회합니다.
    /// - Parameter id: 조회할 음성 메모의 ID
    /// - Returns: 조회된 `VoiceNote` 엔티티
    /// - Throws: 조회 실패 시
    func execute(byId id: UUID) async throws -> VoiceNote
}

public struct DefaultReadVoiceNoteUseCase: ReadVoiceNoteUseCase {

    private let repository: VoiceNoteRepository

    public init(repository: VoiceNoteRepository) {
        self.repository = repository
    }

    public func execute(folderID: UUID) async throws -> [VoiceNote] {
        try await repository.fetchAll(folderID: folderID)
    }

    public func execute(byId id: UUID) async throws -> VoiceNote {
        try await repository.fetch(byId: id)
    }
}
