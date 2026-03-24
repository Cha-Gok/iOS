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
    public typealias DomainType = Keyword

    public convenience init(domain: DomainType, context: NSManagedObjectContext) {
        self.init(context: context)
        insert(from: domain)
    }

    public func toDomain() -> DomainType {
        Keyword(
            id: id,
            noteId: voiceNote.id,
            word: word
        )
    }

    public func insert(from domain: DomainType) {
        id = domain.id
        word = domain.word
    }

    public static var entityName: CoreDataEntityName {
        .keyword
    }

    public static var sortDescriptors: [NSSortDescriptor] {
        [NSSortDescriptor(keyPath: \KeywordEntity.word, ascending: true)]
    }

    public static func identityPredicate(for domain: DomainType) -> NSPredicate {
        NSPredicate(format: "id == %@", domain.id as CVarArg)
    }

    public static func identityPredicate(byId id: DomainType.ID) -> NSPredicate {
        NSPredicate(format: "id == %@", id as CVarArg)
    }

    public static func find(for domain: DomainType, in context: NSManagedObjectContext) throws
        -> Self?
    {
        let request = NSFetchRequest<Self>(entityName: entityName.rawValue)
        request.predicate = identityPredicate(for: domain)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    public static func find(byId id: DomainType.ID, in context: NSManagedObjectContext) throws
        -> Self?
    {
        let request = NSFetchRequest<Self>(entityName: entityName.rawValue)
        request.predicate = identityPredicate(byId: id)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }
}
