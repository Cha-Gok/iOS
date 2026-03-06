import Core
import Foundation

/// 음성 메모 조회 유스케이스 프로토콜.
public protocol ReadVoiceNoteUseCase: Sendable {
    /// 특정 폴더의 모든 음성 메모를 조회합니다.
    /// - Parameter folderID: 조회할 폴더의 ID
    /// - Returns: 조회된 `VoiceNote` 배열
    /// - Throws: `VoiceNoteUseCaseError` (목록 조회 실패)
    func execute(folderID: UUID) async throws(VoiceNoteUseCaseError) -> [VoiceNote]

    /// 특정 음성 메모를 조회합니다.
    /// - Parameter id: 조회할 음성 메모의 ID
    /// - Returns: 조회된 `VoiceNote` 엔티티
    /// - Throws: `VoiceNoteUseCaseError` (레코드 없음, 단건 조회 실패)
    func execute(byId id: UUID) async throws(VoiceNoteUseCaseError) -> VoiceNote
}

public struct DefaultReadVoiceNoteUseCase: ReadVoiceNoteUseCase {

    private let repository: VoiceNoteRepository

    public init(repository: VoiceNoteRepository) {
        self.repository = repository
    }

    public func execute(folderID: UUID) async throws(VoiceNoteUseCaseError) -> [VoiceNote] {
        do {
            return try await repository.fetchAll(folderID: folderID)
        } catch {
            AppLogger.error(error)
            throw mapFromRepository(error)
        }
    }

    public func execute(byId id: UUID) async throws(VoiceNoteUseCaseError) -> VoiceNote {
        do {
            return try await repository.fetch(byId: id)
        } catch {
            AppLogger.error(error)
            throw mapFromRepository(error)
        }
    }

    private func mapFromRepository(_ error: VoiceNoteRepositoryError) -> VoiceNoteUseCaseError {
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
