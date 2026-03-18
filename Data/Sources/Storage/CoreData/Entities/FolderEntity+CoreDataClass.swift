import CoreData
import Foundation

@objc(FolderEntity)
public class FolderEntity: NSManagedObject {
    @NSManaged
    public var id: UUID

    @NSManaged
    public var name: String

    @NSManaged
    public var path: URL

    @NSManaged
    public var createdAt: Date

    @NSManaged
    public var updatedAt: Date

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
