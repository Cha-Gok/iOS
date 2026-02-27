public import Foundation
public import CoreData

public typealias SummaryCoreDataPropertiesSet = NSSet

extension Summary {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Summary> {
        return NSFetchRequest<Summary>(entityName: "Summary")
    }

    @NSManaged public var createdAt: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var text: String?
    @NSManaged public var voiceNote: VoiceNote?

}
