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

    public enum ChildType: Sendable {
        case keyword(Keyword)
        case transcript(Transcript)
        case summary(Summary)
    }

    public var children: [ChildType] {
        var items: [ChildType] = []

        let keywordsDomain = (keywords as? Set<KeywordEntity> ?? []).map { $0.toDomain() }
        items.append(contentsOf: keywordsDomain.map { .keyword($0) })

        if let t = transcript?.toDomain() {
            items.append(.transcript(t))
        }
        if let s = summary?.toDomain() {
            items.append(.summary(s))
        }
        return items
    }

    public convenience init(domain: VoiceNote, context: NSManagedObjectContext) {
        self.init(context: context)
        insert(from: domain)
    }

    public func toDomain() -> VoiceNote {
        var keys: [Keyword] = []
        var t: Transcript?
        var s: Summary?

        for child in children {
            switch child {
            case .keyword(let val): keys.append(val)
            case .transcript(let val): t = val
            case .summary(let val): s = val
            }
        }

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

    public static var entityName: String {
        "VoiceNoteEntity"
    }

    public static var sortDescriptors: [NSSortDescriptor] {
        [NSSortDescriptor(keyPath: \VoiceNoteEntity.createdAt, ascending: true)]
    }

    public static func identityPredicate(for domain: VoiceNote) -> NSPredicate {
        NSPredicate(format: "id == %@", domain.id as CVarArg)
    }

    public static func find(for domain: VoiceNote, in context: NSManagedObjectContext) throws -> Self? {
        let request = NSFetchRequest<Self>(entityName: entityName)
        request.predicate = identityPredicate(for: domain)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }
}
