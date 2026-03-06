import Core
import Foundation

/// 음성 메모 삭제 유스케이스 프로토콜.
public protocol DeleteVoiceNoteUseCase: Sendable {
    /// 음성 메모를 삭제합니다.
    /// - Parameter id: 삭제할 음성 메모의 ID
    /// - Throws: `VoiceNoteUseCaseError` (삭제 실패)
    func execute(byId id: UUID) async throws(VoiceNoteUseCaseError)
}

public struct DefaultDeleteVoiceNoteUseCase: DeleteVoiceNoteUseCase {

    private let repository: VoiceNoteRepository

    public init(repository: VoiceNoteRepository) {
        self.repository = repository
    }

    public func execute(byId id: UUID) async throws(VoiceNoteUseCaseError) {
        do {
            try await repository.delete(byId: id)
        } catch {
            AppLogger.error(error)
            throw mapFromRepository(error)
        }
    }

    private func mapFromRepository(_ error: VoiceNoteRepositoryError) -> VoiceNoteUseCaseError {
        switch error {
        case .deleteFailed(let id):
            return .deleteFailed(id: id)
        case .createFailed, .fetchAllFailed, .recordNotFound, .fetchFailed, .updateFailed, .unknown:
            return .unknown(error)
        }
    }
}
