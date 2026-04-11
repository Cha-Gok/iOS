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
    public var segmentsData: Data?

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
        let segments = (segmentsData.flatMap { try? JSONDecoder().decode([TranscriptSegment].self, from: $0) }) ?? []
        return Transcript(
            id: id,
            createdAt: createdAt,
            text: text,
            segments: segments
        )
    }

    public func insert(from model: ModelType) throws {
        id = model.id
        text = model.text
        createdAt = model.createdAt
        segmentsData = try? JSONEncoder().encode(model.segments)
    }

    public static var entityName: CoreDataEntityName {
        .transcript
    }

    public static var sortDescriptors: [NSSortDescriptor] {
        [NSSortDescriptor(keyPath: \TranscriptEntity.createdAt, ascending: true)]
    }
}
