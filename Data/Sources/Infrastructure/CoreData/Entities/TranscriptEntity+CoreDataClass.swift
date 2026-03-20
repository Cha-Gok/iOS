import CoreData
import Domain

@objc(TranscriptEntity)
public final class TranscriptEntity: NSManagedObject {
    @NSManaged
    public var id: UUID

    @NSManaged
    public var text: String

    @NSManaged
    public var createdAt: Date

    @NSManaged
    public var voiceNote: VoiceNoteEntity
}

public extension TranscriptEntity {
    func toDomain() -> Transcript {
        Transcript(
            id: id,
            createdAt: createdAt,
            text: text
        )
    }
}
