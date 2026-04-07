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

extension KeywordEntity: ManagedObjectMapping {
    public typealias ModelType = Keyword

    public convenience init(model: ModelType, context: NSManagedObjectContext) throws {
        self.init(context: context)
        try insert(from: model)
    }

    public func toModel() -> ModelType {
        Keyword(
            id: id,
            noteID: voiceNote.id,
            word: word
        )
    }

    public func insert(from model: ModelType) throws {
        id = model.id
        word = model.word
    }

    public static var entityName: CoreDataEntityName {
        .keyword
    }

    public static var sortDescriptors: [NSSortDescriptor] {
        [NSSortDescriptor(keyPath: \KeywordEntity.word, ascending: true)]
    }
}
