import Domain

extension FolderEntity {
    func toDomain() -> Folder {
        Folder(
            id: id,
            path: path,
            name: name,
            createdAt: createdAt,
            content: toDomainContent(),
            isDeletable: isDeletable,
            deletedAt: deletedAt
        )
    }

    private func toDomainContent() -> [VoiceNote] {
        let voiceNotes = voiceNotes as? Set<VoiceNoteEntity> ?? []
        return voiceNotes.map { $0.toDomain() }
    }
}
