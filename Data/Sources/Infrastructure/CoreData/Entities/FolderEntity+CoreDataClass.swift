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
    public var kindRaw: String

    @NSManaged
    public var deletedAt: Date?

    @NSManaged
    public var parentID: UUID?

    @NSManaged
    public var voiceNotes: NSSet?
}

extension FolderEntity {
    static func fetchRequest() -> NSFetchRequest<FolderEntity> {
        NSFetchRequest<FolderEntity>(entityName: "Folder")
    }

    convenience init(model: Folder, context: NSManagedObjectContext) {
        self.init(context: context)
        update(from: model)
    }

    func update(from model: Folder) {
        id = model.id
        name = model.name
        createdAt = model.createdAt
        kindRaw = model.kind.rawValue
        deletedAt = model.deletedAt
        parentID = model.parentID
    }

    func toModel() -> Folder {
        let aliveNoteIDs = (voiceNotes as? Set<VoiceNoteEntity>)?
            .filter { $0.deletedAt == nil }
            .map(\.id) ?? []
        return Folder(
            id: id,
            name: name,
            createdAt: createdAt,
            voiceNoteIDs: aliveNoteIDs,
            kind: FolderKind(rawValue: kindRaw) ?? .custom,
            deletedAt: deletedAt,
            parentID: parentID
        )
    }
}
