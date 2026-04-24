import CoreData

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
    public var analysisStateRaw: String?

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

