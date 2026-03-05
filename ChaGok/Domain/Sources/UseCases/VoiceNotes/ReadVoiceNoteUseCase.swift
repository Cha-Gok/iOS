import Core
import Foundation

/// 음성 메모 조회 유스케이스 프로토콜.
public protocol ReadVoiceNoteUseCase: Sendable {
    /// 특정 폴더의 모든 음성 메모를 조회합니다.
    /// - Parameter folderID: 조회할 폴더의 ID
    /// - Returns: 조회된 `VoiceNote` 배열
    /// - Throws: `ReadVoiceNoteUseCaseError` (목록 조회 실패)
    func execute(folderID: UUID) async throws(ReadVoiceNoteUseCaseError) -> [VoiceNote]

    /// 특정 음성 메모를 조회합니다.
    /// - Parameter id: 조회할 음성 메모의 ID
    /// - Returns: 조회된 `VoiceNote` 엔티티
    /// - Throws: `ReadVoiceNoteUseCaseError` (레코드 없음, 단건 조회 실패)
    func execute(byId id: UUID) async throws(ReadVoiceNoteUseCaseError) -> VoiceNote
}

public struct DefaultReadVoiceNoteUseCase: ReadVoiceNoteUseCase {

    private let repository: VoiceNoteRepository

    public init(repository: VoiceNoteRepository) {
        self.repository = repository
    }

    public func execute(folderID: UUID) async throws(ReadVoiceNoteUseCaseError) -> [VoiceNote] {
        do {
            return try await repository.fetchAll(folderID: folderID)
        } catch {
            let useCaseError = mapFromRepository(error)
            throw useCaseError
        }
    }

    public func execute(byId id: UUID) async throws(ReadVoiceNoteUseCaseError) -> VoiceNote {
        do {
            return try await repository.fetch(byId: id)
        } catch {
            let useCaseError: ReadVoiceNoteUseCaseError = mapFromRepository(error)
            throw useCaseError
        }
    }

    private func mapFromRepository(_ error: VoiceNoteRepositoryError) -> ReadVoiceNoteUseCaseError {
        switch error {
        case .fetchAllFailed(let folderID):
            return .fetchAllFailed(folderID: folderID)
        case .recordNotFound(let id):
            return .recordNotFound(id: id)
        case .fetchFailed(let id):
            return .fetchFailed(id: id)
        case .createFailed, .updateFailed, .deleteFailed, .unknown:
            return .unknown(error)
        }
    }
}
