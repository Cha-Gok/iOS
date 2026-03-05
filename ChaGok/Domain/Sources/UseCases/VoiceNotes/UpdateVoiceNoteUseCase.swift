import Foundation

/// 음성 메모 업데이트 유스케이스 프로토콜.
public protocol UpdateVoiceNoteUseCase: Sendable {
    /// 음성 메모 정보를 업데이트합니다.
    /// - Parameter voiceNote: 업데이트할 `VoiceNote` 엔티티
    /// - Returns: 업데이트된 `VoiceNote` 엔티티
    /// - Throws: 업데이트 실패 시
    func execute(_ voiceNote: VoiceNote) async throws -> VoiceNote
}

public struct DefaultUpdateVoiceNoteUseCase: UpdateVoiceNoteUseCase {

    private let repository: VoiceNoteRepository

    public init(repository: VoiceNoteRepository) {
        self.repository = repository
    }

    public func execute(_ voiceNote: VoiceNote) async throws -> VoiceNote {
        try await repository.update(voiceNote)
    }
}
