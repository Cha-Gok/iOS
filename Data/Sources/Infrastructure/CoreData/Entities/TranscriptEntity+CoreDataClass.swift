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
    public var sectionsData: Data

    @NSManaged
    public var voiceNote: VoiceNoteEntity
}

extension TranscriptEntity {
    static func fetchRequest() -> NSFetchRequest<TranscriptEntity> {
        NSFetchRequest<TranscriptEntity>(entityName: "Transcript")
    }

    convenience init(model: Transcript, context: NSManagedObjectContext) {
        self.init(context: context)
        update(from: model)
    }

    func update(from model: Transcript) {
        id = model.id
        createdAt = model.createdAt
        updatedAt = model.updatedAt
        sectionsData = (try? JSONEncoder().encode(model.sections)) ?? Data()
    }

    func toModel() -> Transcript {
        let sections = (try? JSONDecoder().decode([TranscriptSection].self, from: sectionsData)) ?? []
        return Transcript(
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt ?? createdAt,
            sections: sections
        )
    }
}
