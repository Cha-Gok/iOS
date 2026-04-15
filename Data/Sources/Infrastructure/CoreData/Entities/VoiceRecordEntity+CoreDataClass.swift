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

extension VoiceRecordEntity: ManagedObjectMapping {
    public typealias ModelType = VoiceRecord

    public convenience init(model: ModelType, context: NSManagedObjectContext) throws {
        self.init(context: context)
        try insert(from: model)
    }

    public func toModel() -> ModelType {
        VoiceRecord(
            id: id,
            createdAt: createdAt,
            audioFilePath: audioFilePath,
            duration: duration
        )
    }

    public func insert(from model: ModelType) throws {
        id = model.id
        audioFilePath = model.audioFilePath
        duration = model.duration
        createdAt = model.createdAt
    }

    public static var entityName: CoreDataEntityName {
        .voiceRecord
    }

    public static var sortDescriptors: [NSSortDescriptor] {
        [NSSortDescriptor(keyPath: \VoiceRecordEntity.createdAt, ascending: true)]
    }
}
