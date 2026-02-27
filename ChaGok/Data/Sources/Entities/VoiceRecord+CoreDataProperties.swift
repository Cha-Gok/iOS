public import Foundation
public import CoreData

public typealias VoiceRecordCoreDataPropertiesSet = NSSet

extension VoiceRecord {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<VoiceRecord> {
        return NSFetchRequest<VoiceRecord>(entityName: "VoiceRecord")
    }

    @NSManaged public var audioFilePath: URL?
    @NSManaged public var createdAt: Date?
    @NSManaged public var duration: Double
    @NSManaged public var id: UUID?
    @NSManaged public var voiceNote: VoiceNote?

}
