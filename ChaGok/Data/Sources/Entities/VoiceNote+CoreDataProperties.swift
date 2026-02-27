public import Foundation
public import CoreData

public typealias VoiceNoteCoreDataPropertiesSet = NSSet

extension VoiceNote {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<VoiceNote> {
        return NSFetchRequest<VoiceNote>(entityName: "VoiceNote")
    }

    @NSManaged public var createdAt: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var folder: Folder?
    @NSManaged public var keywords: NSSet?
    @NSManaged public var summary: Summary?
    @NSManaged public var transcript: Transcript?
    @NSManaged public var voiceRecord: VoiceRecord?

}

// MARK: Generated accessors for keywords
extension VoiceNote {

    @objc(addKeywordsObject:)
    @NSManaged public func addToKeywords(_ value: Keyword)

    @objc(removeKeywordsObject:)
    @NSManaged public func removeFromKeywords(_ value: Keyword)

    @objc(addKeywords:)
    @NSManaged public func addToKeywords(_ values: NSSet)

    @objc(removeKeywords:)
    @NSManaged public func removeFromKeywords(_ values: NSSet)

}
