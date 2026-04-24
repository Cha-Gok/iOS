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
    public var originalFolderID: UUID?

    @NSManaged
    public var deletedWithFolder: Bool

    @NSManaged
    public var analysisStateRaw: String

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

extension VoiceNoteEntity {
    static func fetchRequest() -> NSFetchRequest<VoiceNoteEntity> {
        NSFetchRequest<VoiceNoteEntity>(entityName: "VoiceNote")
    }

    /// 도메인 모델로부터 새 entity를 생성합니다. (scalar attribute만 set, 관계는 caller가 처리)
    convenience init(model: VoiceNote, context: NSManagedObjectContext) {
        self.init(context: context)
        update(from: model)
    }

    /// scalar attribute만 도메인 모델 값으로 업데이트합니다.
    /// 관계(folder/voiceRecord/keywords/transcript/summary)는 호출자가 직접 set합니다.
    func update(from model: VoiceNote) {
        id = model.id
        title = model.title
        createdAt = model.createdAt
        updatedAt = model.updatedAt
        deletedAt = model.deletedAt
        originalFolderID = model.originalFolderID
        deletedWithFolder = model.deletedWithFolder
        analysisStateRaw = model.analysisState.rawValue
    }

    /// entity를 도메인 모델로 변환합니다. 관계는 이미 attached됐다고 가정합니다.
    func toModel() -> VoiceNote {
        let keywordModels = (keywords?.allObjects as? [KeywordEntity])?.map { $0.toModel() } ?? []
        let state = AnalysisState(rawValue: analysisStateRaw) ?? .pending

        return VoiceNote(
            id: id,
            title: title,
            createdAt: createdAt,
            updatedAt: updatedAt,
            folderID: folder.id,
            voiceRecord: voiceRecord.toModel(),
            keywords: keywordModels,
            transcript: transcript?.toModel(),
            summary: summary?.toModel(),
            deletedAt: deletedAt,
            originalFolderID: originalFolderID,
            deletedWithFolder: deletedWithFolder,
            analysisState: state
        )
    }
}
