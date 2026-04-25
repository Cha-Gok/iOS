import CoreData
import Domain

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

extension VoiceRecordEntity {
    static func fetchRequest() -> NSFetchRequest<VoiceRecordEntity> {
        NSFetchRequest<VoiceRecordEntity>(entityName: "VoiceRecord")
    }

    convenience init(model: VoiceRecord, context: NSManagedObjectContext) {
        self.init(context: context)
        update(from: model)
    }

    func update(from model: VoiceRecord) {
        id = model.id
        audioFilePath = model.audioFilePath
        duration = model.duration
        createdAt = model.createdAt
    }

    func toModel() -> VoiceRecord {
        VoiceRecord(
            id: id,
            createdAt: createdAt,
            audioFilePath: audioFilePath,
            duration: duration
        )
    }
}
