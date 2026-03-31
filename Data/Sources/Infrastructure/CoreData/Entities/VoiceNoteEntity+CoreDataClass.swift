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
    public typealias ModelType = VoiceNote

    public convenience init(model: VoiceNote, context: NSManagedObjectContext) throws {
        self.init(context: context)
        try insert(from: model)
    }

    public func toModel() -> VoiceNote {
        // 엔티티의 연관 관계를 개별적으로 도메인 모델로 변환
        let keys = (keywords as? Set<KeywordEntity> ?? []).map { $0.toModel() }
        let t = transcript?.toModel()
        let s = summary?.toModel()

        return VoiceNote(
            id: id,
            title: title,
            createdAt: createdAt,
            updatedAt: updatedAt,
            folderID: folder.id,
            voiceRecord: voiceRecord.toModel(),
            keywords: keys,
            transcript: t,
            summary: s,
            deletedAt: deletedAt
        )
    }

    public func insert(from model: VoiceNote) throws {
        id = model.id
        title = model.title
        createdAt = model.createdAt
        updatedAt = model.updatedAt
        deletedAt = model.deletedAt

        guard let context = managedObjectContext else { return }

        // 1. Folder Relationship (필수 — folderID에 해당하는 폴더는 반드시 존재)
        if let existingFolder = try? FolderEntity.find(byId: model.folderID, in: context) {
            folder = existingFolder
        } else {
            throw CoreDataStorageError.relationNotFound("Folder(\(model.folderID))")
        }

        // 2. VoiceRecord (위임)
        let record = try VoiceRecordEntity(model: model.voiceRecord, context: context)
        record.voiceNote = self
        voiceRecord = record

        // 3. Transcript (위임)
        if let t = model.transcript {
            let tEntity = try TranscriptEntity(model: t, context: context)
            tEntity.voiceNote = self
            transcript = tEntity
        }

        // 4. Summary (위임)
        if let s = model.summary {
            let sEntity = try SummaryEntity(model: s, context: context)
            sEntity.voiceNote = self
            summary = sEntity
        }

        // 5. Keywords (위임)
        var keywordEntities: [KeywordEntity] = []
        for keywordModel in model.keywords {
            let keywordEntity = try KeywordEntity(model: keywordModel, context: context)
            keywordEntity.voiceNote = self
            keywordEntities.append(keywordEntity)
        }
        keywords = NSSet(array: keywordEntities)
    }

    public func update(from model: VoiceNote) throws {
        // 1. 전체 데이터가 동일하면 즉시 종료 (최적화)
        if toModel() == model { return }

        // 2. 기본 필드 수정
        title = model.title
        updatedAt = model.updatedAt
        deletedAt = model.deletedAt

        guard let context = managedObjectContext else { return }

        // 3. Folder 관계 (변경 시에만)
        if folder.id != model.folderID {
            if let newFolder = try? FolderEntity.find(byId: model.folderID, in: context) {
                folder = newFolder
            } else {
                throw CoreDataStorageError.relationNotFound("Folder(\(model.folderID))")
            }
        }

        // --- 비즈니스 시나리오 순서: Transcript 생성 후 Summary/Keywords 생성 ---

        // 4. Transcript 업데이트
        if let tModel = model.transcript {
            if let tEntity = transcript {
                try tEntity.update(from: tModel)
            } else {
                let tEntity = try TranscriptEntity(model: tModel, context: context)
                tEntity.voiceNote = self
                transcript = tEntity
            }
        } else if let oldT = transcript {
            context.delete(oldT)
            transcript = nil
        }

        // 5. Summary 업데이트
        if let sModel = model.summary {
            if let sEntity = summary {
                try sEntity.update(from: sModel)
            } else {
                let sEntity = try SummaryEntity(model: sModel, context: context)
                sEntity.voiceNote = self
                summary = sEntity
            }
        } else if let oldS = summary {
            context.delete(oldS)
            summary = nil
        }

        // 6. Keywords 업데이트 (위임 위주 Diff)
        let currentKeywords = (keywords as? Set<KeywordEntity>) ?? []
        let newWordSet = Set(model.keywords.map(\.word))

        // (1) 삭제 처리
        for entity in currentKeywords {
            if !newWordSet.contains(entity.word) {
                context.delete(entity)
            }
        }

        // (2) 추가 처리 (자식 객체 스스로 매핑하도록 위임)
        let currentWordSet = Set(currentKeywords.map(\.word))
        for keywordModel in model.keywords {
            if !currentWordSet.contains(keywordModel.word) {
                let newKeyword = try KeywordEntity(model: keywordModel, context: context)
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
}
