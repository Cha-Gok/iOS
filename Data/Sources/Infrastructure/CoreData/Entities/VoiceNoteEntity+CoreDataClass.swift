import CoreData
import Domain

@objc(VoiceNoteEntity)
public final class VoiceNoteEntity: NSManagedObject {
    @NSManaged
    public var id: UUID

    @NSManaged
    public var title: String

    @NSManaged
    public var createdAt: Date

    @NSManaged
    public var updatedAt: Date

    @NSManaged
    public var deletedAt: Date?

    @NSManaged
    public var folder: FolderEntity

    @NSManaged
    public var voiceRecord: VoiceRecordEntity

    @NSManaged
    public var keywords: NSSet?

    @NSManaged
    public var transcript: TranscriptEntity?

    @NSManaged
    public var summary: SummaryEntity?
}

public extension VoiceNoteEntity {
    @objc(addKeywordsObject:)
    @NSManaged
    func addToKeywords(_ value: KeywordEntity)

    @objc(removeKeywordsObject:)
    @NSManaged
    func removeFromKeywords(_ value: KeywordEntity)

    @objc(addKeywords:)
    @NSManaged
    func addToKeywords(_ values: NSSet)

    @objc(removeKeywords:)
    @NSManaged
    func removeFromKeywords(_ values: NSSet)
}

extension VoiceNoteEntity: ManagedObjectMapping {
    public typealias DomainType = VoiceNote

    public convenience init(domain: VoiceNote, context: NSManagedObjectContext) {
        self.init(context: context)
        insert(from: domain)
    }

    public func toDomain() -> VoiceNote {
        // 엔티티의 연관 관계를 개별적으로 도메인 모델로 변환
        let keys = (keywords as? Set<KeywordEntity> ?? []).map { $0.toDomain() }
        let t = transcript?.toDomain()
        let s = summary?.toDomain()

        return VoiceNote(
            id: id,
            title: title,
            createdAt: createdAt,
            updatedAt: updatedAt,
            folderID: folder.id,
            voiceRecord: voiceRecord.toDomain(),
            keywords: keys,
            transcript: t,
            summary: s,
            deletedAt: deletedAt
        )
    }

    public func insert(from domain: VoiceNote) {
        id = domain.id
        title = domain.title
        createdAt = domain.createdAt
        updatedAt = domain.updatedAt
        deletedAt = domain.deletedAt
        // 연관된 엔티티(VoiceRecord, Keywords, Transcript, Summary 등)의 insert는
        // 필요에 따라 Repository 계층이나 별도 매핑 로직에서 처리합니다.
    }

    public static var entityName: CoreDataEntityName {
        .voiceNote
    }

    public static var sortDescriptors: [NSSortDescriptor] {
        [NSSortDescriptor(keyPath: \VoiceNoteEntity.createdAt, ascending: true)]
    }

    public static func identityPredicate(for domain: DomainType) -> NSPredicate {
        NSPredicate(format: "id == %@", domain.id as CVarArg)
    }

    public static func identityPredicate(byId id: DomainType.ID) -> NSPredicate {
        NSPredicate(format: "id == %@", id as CVarArg)
    }

    public static func find(for domain: DomainType, in context: NSManagedObjectContext) throws -> Self? {
        let request = NSFetchRequest<Self>(entityName: entityName.rawValue)
        request.predicate = identityPredicate(for: domain)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    public static func find(byId id: DomainType.ID, in context: NSManagedObjectContext) throws -> Self? {
        let request = NSFetchRequest<Self>(entityName: entityName.rawValue)
        request.predicate = identityPredicate(byId: id)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }
}
