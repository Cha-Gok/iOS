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

extension SummaryEntity {
    static func fetchRequest() -> NSFetchRequest<SummaryEntity> {
        NSFetchRequest<SummaryEntity>(entityName: "Summary")
    }

    convenience init(model: Summary, context: NSManagedObjectContext) {
        self.init(context: context)
        update(from: model)
    }

    func update(from model: Summary) {
        id = model.id
        text = model.text
        createdAt = model.createdAt
    }

    func toModel() -> Summary {
        Summary(
            id: id,
            createdAt: createdAt,
            text: text
        )
    }
}
