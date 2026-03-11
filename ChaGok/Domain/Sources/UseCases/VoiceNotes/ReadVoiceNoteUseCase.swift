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

    private let repository: VoiceNoteFetchRepository

    public init(repository: VoiceNoteFetchRepository) {
        self.repository = repository
    }

    public func execute(folderID: UUID) async throws(ReadVoiceNoteUseCaseError) -> [VoiceNote] {
        if Task.isCancelled { throw .cancelled }
        do {
            return try await repository.fetchAll(folderID: folderID)
        } catch {
            AppLogger.error(error)
            throw ReadVoiceNoteUseCaseError(error)
        }
    }

    public func execute(byId id: UUID) async throws(ReadVoiceNoteUseCaseError) -> VoiceNote {
        if Task.isCancelled { throw .cancelled }
        do {
            return try await repository.fetch(byId: id)
        } catch {
            AppLogger.error(error)
            throw ReadVoiceNoteUseCaseError(error)
        }
    }
}

extension ReadVoiceNoteUseCaseError {
    public init(_ error: VoiceNoteFetchRepositoryError) {
        switch error {
        case .fetchAllFailed(let folderID):
            self = .fetchAllFailed(folderID: folderID)
        case .recordNotFound(let id):
            self = .recordNotFound(id: id)
        case .fetchFailed(let id):
            self = .fetchFailed(id: id)
        case .cancelled:
            self = .cancelled
        case .unknown(let error):
            self = .unknown(error)
        }
    }
}
