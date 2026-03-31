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
    public typealias ModelType = Folder

    public convenience init(model: ModelType, context: NSManagedObjectContext) throws {
        self.init(context: context)
        try insert(from: model)
    }

    public func toModel() -> ModelType {
        // voiceNotes는 별도 fetch로 가져오도록 빈 배열로 반환합니다.
        // Folder.toModel() 시 모든 VoiceNote + 하위 관계를 재귀 로드하는 성능 문제를 방지합니다.
        Folder(
            id: id,
            name: name,
            createdAt: createdAt,
            content: [],
            isDeletable: isDeletable,
            deletedAt: deletedAt
        )
    }

    public func insert(from model: ModelType) throws {
        id = model.id
        name = model.name
        createdAt = model.createdAt
        isDeletable = model.isDeletable
        deletedAt = model.deletedAt
    }

    /// Folder의 스칼라 속성만 비교하여 변경된 경우에만 수정합니다.
    /// voiceNotes 관계는 VoiceNote 쪽에서 folder를 직접 관리하므로 여기서 건드리지 않습니다.
    public func update(from model: ModelType) throws {
        if name == model.name,
           isDeletable == model.isDeletable,
           deletedAt == model.deletedAt
        {
            return
        }
        name = model.name
        isDeletable = model.isDeletable
        deletedAt = model.deletedAt
    }

    public static var entityName: CoreDataEntityName {
        .folder
    }

    public static var sortDescriptors: [NSSortDescriptor] {
        [NSSortDescriptor(keyPath: \FolderEntity.createdAt, ascending: false)]
    }
}
