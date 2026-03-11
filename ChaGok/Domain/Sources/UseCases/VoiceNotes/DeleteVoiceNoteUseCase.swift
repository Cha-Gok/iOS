import Core
import Foundation

/// 음성 메모 삭제 유스케이스 프로토콜.
public protocol DeleteVoiceNoteUseCase: Sendable {
    /// 음성 메모를 삭제합니다.
    /// - Parameter id: 삭제할 음성 메모의 ID
    /// - Throws: `DeleteVoiceNoteUseCaseError` (삭제 실패)
    func execute(byId id: UUID) async throws(DeleteVoiceNoteUseCaseError)
}

public struct DefaultDeleteVoiceNoteUseCase: DeleteVoiceNoteUseCase {

    private let repository: VoiceNoteDeleteRepository

    public init(repository: VoiceNoteDeleteRepository) {
        self.repository = repository
    }

    public func execute(byId id: UUID) async throws(DeleteVoiceNoteUseCaseError) {
        if Task.isCancelled { throw .cancelled }

        do {
            try await repository.delete(byId: id)
        } catch {
            AppLogger.error(error)
            throw DeleteVoiceNoteUseCaseError(error)
        }
    }
}

extension DeleteVoiceNoteUseCaseError {
    public init(_ error: VoiceNoteDeleteRepositoryError) {
        switch error {
        case .deleteFailed(let id):
            self = .deleteFailed(id: id)
        case .cancelled:
            self = .cancelled
        case .unknown(let err):
            self = .unknown(err)
        }
    }
}
