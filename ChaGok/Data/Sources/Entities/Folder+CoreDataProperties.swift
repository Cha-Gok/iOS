public import Foundation
public import CoreData

public typealias FolderCoreDataPropertiesSet = NSSet

extension Folder {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Folder> {
        return NSFetchRequest<Folder>(entityName: "Folder")
    }

    @NSManaged public var createdAt: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var path: URL?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var voiceNotes: NSSet?

}

// MARK: Generated accessors for voiceNotes
extension Folder {

    @objc(addVoiceNotesObject:)
    @NSManaged public func addToVoiceNotes(_ value: VoiceNote)

    @objc(removeVoiceNotesObject:)
    @NSManaged public func removeFromVoiceNotes(_ value: VoiceNote)

    @objc(addVoiceNotes:)
    @NSManaged public func addToVoiceNotes(_ values: NSSet)

    @objc(removeVoiceNotes:)
    @NSManaged public func removeFromVoiceNotes(_ values: NSSet)

}
