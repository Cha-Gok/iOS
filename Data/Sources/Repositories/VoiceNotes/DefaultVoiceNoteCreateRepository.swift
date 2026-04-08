import Core
import Domain

/// VoiceNote 생성 리포지토리 구현체.
/// 항상 기본 폴더(`isDeletable: false`)에 음성 메모를 생성합니다.
public struct DefaultVoiceNoteCreateRepository: VoiceNoteCreateRepository {
    private let store: CoreDataLocalDataBase

    public init(store: CoreDataLocalDataBase) {
        self.store = store
    }

    public func create(_ voiceRecord: VoiceRecord) async throws(VoiceNoteCreateRepositoryError) -> VoiceNote {
        if Task.isCancelled { throw .cancelled }

        do {
            let folders = try await store.fetchAll(FolderEntity.self)

            guard let defaultFolder = folders.first(where: { !$0.isDeletable }) else {
                AppLogger.error(VoiceNoteCreateRepositoryError.createFailed)
                throw VoiceNoteCreateRepositoryError.createFailed
            }

            let voiceNote = VoiceNote(
                title: voiceRecord.audioFilePath.deletingPathExtension().lastPathComponent,
                folderID: defaultFolder.id,
                voiceRecord: voiceRecord
            )

            return try await store.create(voiceNote, as: VoiceNoteEntity.self)
        } catch {
            AppLogger.error(error)
            throw .createFailed
        }
    }
}
