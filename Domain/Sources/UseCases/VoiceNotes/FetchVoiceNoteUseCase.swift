import Core
import Foundation

/// 음성 메모 조회 유스케이스 프로토콜.
public protocol FetchVoiceNoteUseCase: Sendable {
    /// 기본 폴더의 모든 음성 메모를 조회합니다.
    /// - Returns: 기본 폴더에 저장된 음성 메모 배열
    /// - Throws: `FetchVoiceNoteUseCaseError`
    func execute() async throws(FetchVoiceNoteUseCaseError) -> [VoiceNote]

    /// 특정 폴더의 모든 음성 메모를 조회합니다.
    /// - Parameter folderID: 조회할 폴더의 ID
    /// - Returns: 조회된 `VoiceNote` 배열
    /// - Throws: `FetchVoiceNoteUseCaseError` (목록 조회 실패)
    func execute(folderID: UUID) async throws(FetchVoiceNoteUseCaseError) -> [VoiceNote]

    /// 특정 음성 메모를 조회합니다.
    /// - Parameter id: 조회할 음성 메모의 ID
    /// - Returns: 조회된 `VoiceNote` 엔티티
    /// - Throws: `FetchVoiceNoteUseCaseError` (레코드 없음, 단건 조회 실패)
    func execute(byId id: UUID) async throws(FetchVoiceNoteUseCaseError) -> VoiceNote
}

public struct DefaultFetchVoiceNoteUseCase: FetchVoiceNoteUseCase {
    private let repository: VoiceNoteFetchRepository

    public init(repository: VoiceNoteFetchRepository) {
        self.repository = repository
    }

    public func execute() async throws(FetchVoiceNoteUseCaseError) -> [VoiceNote] {
        if Task.isCancelled { throw .cancelled }
        do {
            return try await repository.fetchAllFromDefaultFolder()
        } catch {
            AppLogger.error(error)
            throw FetchVoiceNoteUseCaseError(error)
        }
    }

    public func execute(folderID: UUID) async throws(FetchVoiceNoteUseCaseError) -> [VoiceNote] {
        if Task.isCancelled { throw .cancelled }
        let voiceNotes: [VoiceNote]
        do {
            voiceNotes = try await repository.fetchAll(folderID: folderID)
        } catch {
            AppLogger.error(error)
            throw FetchVoiceNoteUseCaseError(error)
        }
        if Task.isCancelled { throw .cancelled }
        return voiceNotes
    }

    public func execute(byId id: UUID) async throws(FetchVoiceNoteUseCaseError) -> VoiceNote {
        if Task.isCancelled { throw .cancelled }
        let voiceNote: VoiceNote
        do {
            voiceNote = try await repository.fetch(byId: id)
        } catch {
            AppLogger.error(error)
            throw FetchVoiceNoteUseCaseError(error)
        }
        if Task.isCancelled { throw .cancelled }
        return voiceNote
    }
}
