import CoreData
import Domain

@objc(SummaryEntity)
public final class SummaryEntity: NSManagedObject {
    @NSManaged
    public var id: UUID

    @NSManaged
    public var text: String

    @NSManaged
    public var createdAt: Date

    @NSManaged
    public var voiceNote: VoiceNoteEntity
}

public extension SummaryEntity {
    func toDomain() -> Summary {
        Summary(
            id: id,
            createdAt: createdAt,
            text: text
        )
    }
}
