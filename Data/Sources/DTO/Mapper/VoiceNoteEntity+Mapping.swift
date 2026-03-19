import Domain

extension VoiceNoteEntity {
    func toDomain() -> VoiceNote {
        VoiceNote(
            id: id,
            title: title,
            createdAt: createdAt,
            updatedAt: updatedAt,
            folderID: folder.id,
            voiceRecord: voiceRecord.toDomain(),
            keywords: [], // 하위 관계는 비워둠
            transcript: nil,
            summary: nil,
            deletedAt: deletedAt
        )
    }
}
