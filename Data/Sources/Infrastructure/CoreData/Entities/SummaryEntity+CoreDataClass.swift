import CoreData
import Foundation

@objc(SummaryEntity)
public class SummaryEntity: NSManagedObject {
    @NSManaged
    public var id: UUID

    @NSManaged
    public var text: String

    @NSManaged
    public var createdAt: Date

    @NSManaged
    public var voiceNote: VoiceNoteEntity
}
