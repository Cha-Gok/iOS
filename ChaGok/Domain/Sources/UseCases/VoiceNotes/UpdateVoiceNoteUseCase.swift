import Foundation

/// 음성 메모 업데이트 유스케이스 프로토콜.
public protocol UpdateVoiceNoteUseCase: Sendable {
    /// 음성 메모 정보를 업데이트합니다.
    /// - Parameter voiceNote: 업데이트할 `VoiceNote` 엔티티
    /// - Returns: 업데이트된 `VoiceNote` 엔티티
    /// - Throws: `UpdateVoiceNoteUseCaseError` (업데이트 실패)
    func execute(_ voiceNote: VoiceNote) async throws(UpdateVoiceNoteUseCaseError) -> VoiceNote
}

public struct DefaultUpdateVoiceNoteUseCase: UpdateVoiceNoteUseCase {

    private let repository: VoiceNoteRepository

    public init(repository: VoiceNoteRepository) {
        self.repository = repository
    }

    public func execute(_ voiceNote: VoiceNote) async throws(UpdateVoiceNoteUseCaseError)
        -> VoiceNote
    {
        do {
            return try await repository.update(voiceNote)
        } catch {
            throw mapFromRepository(error)
        }
    }

    private func mapFromRepository(_ error: VoiceNoteRepositoryError) -> UpdateVoiceNoteUseCaseError
    {
        switch error {
        case .updateFailed:
            return .updateFailed
        case .createFailed, .fetchAllFailed, .recordNotFound, .fetchFailed, .deleteFailed, .unknown:
            return .unknown
        }
    }
}
