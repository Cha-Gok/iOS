import CoreData

@objc(KeywordEntity)
public final class KeywordEntity: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<KeywordEntity> {
        NSFetchRequest<KeywordEntity>(entityName: "Keyword")
    }

    @NSManaged
    public var id: UUID

    @NSManaged
    public var word: String

    @NSManaged
    public var voiceNote: VoiceNoteEntity
}
