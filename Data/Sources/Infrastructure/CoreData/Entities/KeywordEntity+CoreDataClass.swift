import CoreData
import Domain

@objc(KeywordEntity)
public final class KeywordEntity: NSManagedObject {
    @NSManaged
    public var id: UUID

    @NSManaged
    public var word: String

    @NSManaged
    public var voiceNote: VoiceNoteEntity
}

extension KeywordEntity {
    static func fetchRequest() -> NSFetchRequest<KeywordEntity> {
        NSFetchRequest<KeywordEntity>(entityName: "Keyword")
    }

    convenience init(model: Keyword, context: NSManagedObjectContext) {
        self.init(context: context)
        update(from: model)
    }

    func update(from model: Keyword) {
        id = model.id
        word = model.word
    }

    func toModel() -> Keyword {
        Keyword(
            id: id,
            noteID: voiceNote.id,
            word: word
        )
    }
}
