import Foundation

/// 음성 메모 생성 유스케이스 프로토콜.
public protocol CreateVoiceNoteUseCase: Sendable {
    /// 새로운 음성 메모를 생성합니다.
    /// - Parameter voiceNote: 생성할 음성 메모 엔티티
    /// - Returns: 저장된 `VoiceNote` 엔티티
    /// - Throws: 생성 실패 시
    func execute(_ voiceRecord: VoiceRecord) async throws -> VoiceNote
}

public struct DefaultCreateVoiceNoteUseCase: CreateVoiceNoteUseCase {

    private let repository: VoiceNoteRepository

    public init(repository: VoiceNoteRepository) {
        self.repository = repository
    }

    public func execute(_ voiceRecord: VoiceRecord) async throws -> VoiceNote {
        try await repository.create(voiceRecord)
    }
}
