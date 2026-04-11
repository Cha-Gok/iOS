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

    /// JSON 직렬화된 세그먼트 배열. 레거시 데이터는 nil.
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
        var segments: [TranscriptSegment] = []
        if let data = segmentsData {
            segments = (try? JSONDecoder().decode([TranscriptSegment].self, from: data)) ?? []
        }
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
        if !model.segments.isEmpty {
            segmentsData = try? JSONEncoder().encode(model.segments)
        } else {
            segmentsData = nil
        }
    }

    public static var entityName: CoreDataEntityName {
        .transcript
    }

    public static var sortDescriptors: [NSSortDescriptor] {
        [NSSortDescriptor(keyPath: \TranscriptEntity.createdAt, ascending: true)]
    }
}
