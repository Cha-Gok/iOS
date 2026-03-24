import CoreData
import Domain

@objc(VoiceRecordEntity)
public final class VoiceRecordEntity: NSManagedObject {
    @NSManaged
    public var id: UUID

    @NSManaged
    public var audioFilePath: URL

    @NSManaged
    public var createdAt: Date

    @NSManaged
    public var duration: Double

    @NSManaged
    public var voiceNote: VoiceNoteEntity
}

extension VoiceRecordEntity: ManagedObjectMapping {
    public typealias DomainType = VoiceRecord

    public convenience init(domain: DomainType, context: NSManagedObjectContext) {
        self.init(context: context)
        insert(from: domain)
    }

    public func toDomain() -> DomainType {
        VoiceRecord(
            id: id,
            createdAt: createdAt,
            audioFilePath: audioFilePath,
            duration: duration
        )
    }

    public func insert(from domain: DomainType) {
        id = domain.id
        audioFilePath = domain.audioFilePath
        duration = domain.duration
        createdAt = domain.createdAt
    }

    public static var entityName: CoreDataEntityName {
        .voiceRecord
    }

    public static var sortDescriptors: [NSSortDescriptor] {
        [NSSortDescriptor(keyPath: \VoiceRecordEntity.createdAt, ascending: true)]
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
