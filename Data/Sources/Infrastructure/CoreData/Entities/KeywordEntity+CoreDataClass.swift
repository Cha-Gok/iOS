import CoreData
import Domain

@objc(KeywordEntity)
public final class KeywordEntity: NSManagedObject {
    @NSManaged
    public var id: UUID

    @NSManaged
    public var word: String

    @NSManaged
    public var voiceNote: VoiceNoteEntity
}

public extension KeywordEntity {
    func toDomain() -> Keyword {
        Keyword(
            id: id,
            noteId: voiceNote.id,
            word: word
        )
    }
}
