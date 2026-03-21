import CoreData
import Domain

@objc(VoiceRecordEntity)
public final class VoiceRecordEntity: NSManagedObject {
    @NSManaged
    public var id: UUID

    @NSManaged
    public var audioFilePath: URL

    @NSManaged
    public var createdAt: Date

    @NSManaged
    public var duration: Double

    @NSManaged
    public var voiceNote: VoiceNoteEntity
}

public extension VoiceRecordEntity {
    func toDomain() -> VoiceRecord {
        VoiceRecord(
            id: id,
            createdAt: createdAt,
            audioFilePath: audioFilePath,
            duration: duration
        )
    }
}
