import CoreData

@objc(KeywordEntity)
public final class KeywordEntity: NSManagedObject {
    @NSManaged
    public var id: UUID

    @NSManaged
    public var word: String

    @NSManaged
    public var voiceNote: VoiceNoteEntity
}
