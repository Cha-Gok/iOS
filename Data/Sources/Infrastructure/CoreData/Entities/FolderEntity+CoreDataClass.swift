import CoreData
import Domain

@objc(FolderEntity)
public final class FolderEntity: NSManagedObject {
    @NSManaged
    public var id: UUID

    @NSManaged
    public var name: String

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

    public convenience init(domain: DomainType, context: NSManagedObjectContext) {
        self.init(context: context)
        insert(from: domain)
    }

    public func toDomain() -> DomainType {
        // voiceNotes는 별도 fetch로 가져오도록 빈 배열로 반환합니다.
        // Folder.toDomain() 시 모든 VoiceNote + 하위 관계를 재귀 로드하는 성능 문제를 방지합니다.
        Folder(
            id: id,
            name: name,
            createdAt: createdAt,
            content: [],
            isDeletable: isDeletable,
            deletedAt: deletedAt
        )
    }

    public func insert(from domain: DomainType) {
        id = domain.id
        name = domain.name
        createdAt = domain.createdAt
        isDeletable = domain.isDeletable
        deletedAt = domain.deletedAt
    }

    /// Folder의 스칼라 속성만 비교하여 변경된 경우에만 수정합니다.
    /// voiceNotes 관계는 VoiceNote 쪽에서 folder를 직접 관리하므로 여기서 건드리지 않습니다.
    public func update(from domain: DomainType) {
        if name == domain.name,
           isDeletable == domain.isDeletable,
           deletedAt == domain.deletedAt
        {
            return
        }
        name = domain.name
        isDeletable = domain.isDeletable
        deletedAt = domain.deletedAt
    }

    public static var entityName: CoreDataEntityName {
        .folder
    }

    public static var sortDescriptors: [NSSortDescriptor] {
        [NSSortDescriptor(keyPath: \FolderEntity.createdAt, ascending: false)]
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
