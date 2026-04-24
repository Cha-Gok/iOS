import CoreData

@objc(SummaryEntity)
public final class SummaryEntity: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<SummaryEntity> {
        NSFetchRequest<SummaryEntity>(entityName: "Summary")
    }

    @NSManaged
    public var id: UUID

    @NSManaged
    public var text: String

    @NSManaged
    public var createdAt: Date

    @NSManaged
    public var voiceNote: VoiceNoteEntity
}
