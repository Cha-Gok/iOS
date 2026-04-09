import Core
import Domain

/// VoiceNote 업데이트 리포지토리 구현체.
public struct DefaultVoiceNoteUpdateRepository: VoiceNoteUpdateRepository {
    private let store: CoreDataLocalDataBase

    public init(store: CoreDataLocalDataBase) {
        self.store = store
    }

    public func update(_ voiceNote: VoiceNote) async throws(VoiceNoteUpdateRepositoryError) -> VoiceNote {
        if Task.isCancelled { throw .cancelled }
        do {
            return try await store.update(voiceNote, as: VoiceNoteEntity.self)
        } catch {
            AppLogger.error(error)
            throw .updateFailed
        }
    }
}
