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

        guard let context = managedObjectContext else { return }

        // 1. Folder Relationship (필수 — folderID에 해당하는 폴더는 반드시 존재)
        if let existingFolder = try? FolderEntity.find(byId: domain.folderID, in: context) {
            folder = existingFolder
        } else {
            assertionFailure("⚠️ folderID(\(domain.folderID))에 해당하는 폴더가 없습니다.")
        }

        // 2. VoiceRecord (위임)
        let record = VoiceRecordEntity(domain: domain.voiceRecord, context: context)
        record.voiceNote = self
        voiceRecord = record

        // 3. Transcript (위임)
        if let t = domain.transcript {
            let tEntity = TranscriptEntity(domain: t, context: context)
            tEntity.voiceNote = self
            transcript = tEntity
        }

        // 4. Summary (위임)
        if let s = domain.summary {
            let sEntity = SummaryEntity(domain: s, context: context)
            sEntity.voiceNote = self
            summary = sEntity
        }

        // 5. Keywords (위임)
        let keywordEntities = domain.keywords.map { keywordDomain -> KeywordEntity in
            let keywordEntity = KeywordEntity(domain: keywordDomain, context: context)
            keywordEntity.voiceNote = self
            return keywordEntity
        }
        keywords = NSSet(array: keywordEntities)
    }

    public func update(from domain: VoiceNote) {
        // 1. 전체 데이터가 동일하면 즉시 종료 (최적화)
        if toDomain() == domain { return }

        // 2. 기본 필드 수정
        title = domain.title
        updatedAt = domain.updatedAt
        deletedAt = domain.deletedAt

        guard let context = managedObjectContext else { return }

        // 3. Folder 관계 (변경 시에만)
        if folder.id != domain.folderID {
            if let newFolder = try? FolderEntity.find(byId: domain.folderID, in: context) {
                folder = newFolder
            }
        }

        // --- 비즈니스 시나리오 순서: Transcript 생성 후 Summary/Keywords 생성 ---

        // 4. Transcript 업데이트
        if let tDomain = domain.transcript {
            if let tEntity = transcript {
                tEntity.update(from: tDomain)
            } else {
                let tEntity = TranscriptEntity(domain: tDomain, context: context)
                tEntity.voiceNote = self
                transcript = tEntity
            }
        } else if let oldT = transcript {
            context.delete(oldT)
            transcript = nil
        }

        // 5. Summary 업데이트
        if let sDomain = domain.summary {
            if let sEntity = summary {
                sEntity.update(from: sDomain)
            } else {
                let sEntity = SummaryEntity(domain: sDomain, context: context)
                sEntity.voiceNote = self
                summary = sEntity
            }
        } else if let oldS = summary {
            context.delete(oldS)
            summary = nil
        }

        // 6. Keywords 업데이트 (위임 위주 Diff)
        let currentKeywords = (keywords as? Set<KeywordEntity>) ?? []
        let newWordSet = Set(domain.keywords.map(\.word))

        // (1) 삭제 처리
        for entity in currentKeywords {
            if !newWordSet.contains(entity.word) {
                context.delete(entity)
            }
        }

        // (2) 추가 처리 (자식 객체 스스로 매핑하도록 위임)
        let currentWordSet = Set(currentKeywords.map(\.word))
        for keywordDomain in domain.keywords {
            if !currentWordSet.contains(keywordDomain.word) {
                let newKeyword = KeywordEntity(domain: keywordDomain, context: context)
                newKeyword.voiceNote = self
                addToKeywords(newKeyword)
            }
        }
    }

    public static var entityName: CoreDataEntityName {
        .voiceNote
    }

    public static var sortDescriptors: [NSSortDescriptor] {
        [NSSortDescriptor(keyPath: \VoiceNoteEntity.updatedAt, ascending: false)]
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
