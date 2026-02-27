public import Foundation
public import CoreData

public typealias TranscriptCoreDataPropertiesSet = NSSet

extension Transcript {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Transcript> {
        return NSFetchRequest<Transcript>(entityName: "Transcript")
    }

    @NSManaged public var createdAt: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var text: String?
    @NSManaged public var voiceNote: VoiceNote?

}
