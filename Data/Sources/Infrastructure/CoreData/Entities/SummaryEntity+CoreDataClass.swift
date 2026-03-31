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

extension SummaryEntity: ManagedObjectMapping {
    public typealias ModelType = Summary

    public convenience init(model: ModelType, context: NSManagedObjectContext) throws {
        self.init(context: context)
        try insert(from: model)
    }

    public func toModel() -> ModelType {
        Summary(
            id: id,
            createdAt: createdAt,
            text: text
        )
    }

    public func insert(from model: ModelType) throws {
        id = model.id
        text = model.text
        createdAt = model.createdAt
    }

    public static var entityName: CoreDataEntityName {
        .summary
    }

    public static var sortDescriptors: [NSSortDescriptor] {
        [NSSortDescriptor(keyPath: \SummaryEntity.createdAt, ascending: true)]
    }
}
