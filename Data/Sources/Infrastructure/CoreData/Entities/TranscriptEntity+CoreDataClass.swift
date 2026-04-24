import CoreData

@objc(TranscriptEntity)
public final class TranscriptEntity: NSManagedObject {
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
