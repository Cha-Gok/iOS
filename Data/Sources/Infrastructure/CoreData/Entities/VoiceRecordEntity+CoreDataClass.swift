import CoreData

@objc(VoiceRecordEntity)
public final class VoiceRecordEntity: NSManagedObject {
    @NSManaged
    public var id: UUID

    @NSManaged
    public var audioFilePath: String

    @NSManaged
    public var createdAt: Date

    @NSManaged
    public var duration: Double

    @NSManaged
    public var voiceNote: VoiceNoteEntity
}
