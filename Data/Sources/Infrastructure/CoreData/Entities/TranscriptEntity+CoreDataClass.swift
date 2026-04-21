import CoreData
import Domain

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

extension TranscriptEntity: ManagedObjectMapping {
    public typealias ModelType = Transcript

    public convenience init(model: ModelType, context: NSManagedObjectContext) throws {
        self.init(context: context)
        try insert(from: model)
    }

    public func toModel() -> ModelType {
        let sections = (sectionsData.flatMap { try? JSONDecoder().decode([TranscriptSection].self, from: $0) }) ?? []
        return Transcript(
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt ?? createdAt,
            sections: sections
        )
    }

    public func insert(from model: ModelType) throws {
        id = model.id
        createdAt = model.createdAt
        updatedAt = model.updatedAt
        sectionsData = try? JSONEncoder().encode(model.sections)
    }

    public static var entityName: CoreDataEntityName {
        .transcript
    }

    public static var sortDescriptors: [NSSortDescriptor] {
        [NSSortDescriptor(keyPath: \TranscriptEntity.createdAt, ascending: true)]
    }
}
