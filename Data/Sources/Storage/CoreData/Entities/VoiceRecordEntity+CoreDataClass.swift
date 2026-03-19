import CoreData
import Foundation

@objc(VoiceRecordEntity)
public class VoiceRecordEntity: NSManagedObject {
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
