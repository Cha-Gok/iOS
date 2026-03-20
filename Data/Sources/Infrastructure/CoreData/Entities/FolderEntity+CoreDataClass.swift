import CoreData
import Domain

@objc(FolderEntity)
public final class FolderEntity: NSManagedObject {
    @NSManaged
    public var id: UUID

    @NSManaged
    public var name: String

    @NSManaged
    public var path: URL

    @NSManaged
    public var createdAt: Date

    @NSManaged
    public var isDeletable: Bool

    @NSManaged
    public var deletedAt: Date?

    @NSManaged
    public var voiceNotes: NSSet?
}

public extension FolderEntity {
    @objc(addVoiceNotesObject:)
    @NSManaged
    func addToVoiceNotes(_ value: VoiceNoteEntity)

    @objc(removeVoiceNotesObject:)
    @NSManaged
    func removeFromVoiceNotes(_ value: VoiceNoteEntity)

    @objc(addVoiceNotes:)
    @NSManaged
    func addToVoiceNotes(_ values: NSSet)

    @objc(removeVoiceNotes:)
    @NSManaged
    func removeFromVoiceNotes(_ values: NSSet)
}

extension FolderEntity: ManagedObjectMapping {
    public typealias DomainType = Folder
    public typealias ChildType = [VoiceNote]

    public convenience init(domain: Folder, context: NSManagedObjectContext) {
        self.init(context: context)
        insert(from: domain)
    }

    public func toDomain() -> Folder {
        Folder(
            id: id,
            path: path,
            name: name,
            createdAt: createdAt,
            content: child,
            isDeletable: isDeletable,
            deletedAt: deletedAt
        )
    }

    public var child: [VoiceNote] {
        let voiceNotes = voiceNotes as? Set<VoiceNoteEntity> ?? []
        return voiceNotes.map { $0.toDomain() }
    }

    public func insert(from domain: Folder) {
        id = domain.id
        name = domain.name
        path = domain.path
        createdAt = domain.createdAt
        isDeletable = domain.isDeletable
        deletedAt = domain.deletedAt
    }

    public static var entityName: String {
        "FolderEntity"
    }

    public static var sortDescriptors: [NSSortDescriptor] {
        [NSSortDescriptor(keyPath: \FolderEntity.createdAt, ascending: true)]
    }

    public static func identityPredicate(for domain: Folder) -> NSPredicate {
        return NSPredicate(format: "id == %@", domain.id as CVarArg)
    }

    public static func find(for domain: Folder, in context: NSManagedObjectContext) throws -> Self? {
        let request = NSFetchRequest<Self>(entityName: entityName)
        request.predicate = identityPredicate(for: domain)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }
}
