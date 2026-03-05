import Foundation

/// 음성 메모 삭제 유스케이스 프로토콜.
public protocol DeleteVoiceNoteUseCase: Sendable {
    /// 음성 메모를 삭제합니다.
    /// - Parameter id: 삭제할 음성 메모의 ID
    /// - Throws: 삭제 실패 시
    func execute(byId id: UUID) async throws
}

public struct DefaultDeleteVoiceNoteUseCase: DeleteVoiceNoteUseCase {

    private let repository: VoiceNoteRepository

    public init(repository: VoiceNoteRepository) {
        self.repository = repository
    }

    public func execute(byId id: UUID) async throws {
        try await repository.delete(byId: id)
    }
}
