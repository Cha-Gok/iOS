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
    public var voiceNote: VoiceNoteEntity
}

extension TranscriptEntity: ManagedObjectMapping {
    public typealias DomainType = Transcript

    public convenience init(domain: DomainType, context: NSManagedObjectContext) {
        self.init(context: context)
        insert(from: domain)
    }

    public func toDomain() -> DomainType {
        Transcript(
            id: id,
            createdAt: createdAt,
            text: text
        )
    }

    public func insert(from domain: DomainType) {
        id = domain.id
        text = domain.text
        createdAt = domain.createdAt
    }

    public static var entityName: CoreDataEntityName {
        .transcript
    }

    public static var sortDescriptors: [NSSortDescriptor] {
        [NSSortDescriptor(keyPath: \TranscriptEntity.createdAt, ascending: true)]
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
