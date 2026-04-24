import CoreData

@objc(TranscriptEntity)
public final class TranscriptEntity: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<TranscriptEntity> {
        NSFetchRequest<TranscriptEntity>(entityName: "Transcript")
    }

    @NSManaged
    public var id: UUID

    @NSManaged
    public var createdAt: Date

    @NSManaged
    public var updatedAt: Date?

    @NSManaged
    public var sectionsData: Data?

    @NSManaged
    public var voiceNote: VoiceNoteEntity
}
