public import Foundation
public import CoreData

public typealias KeywordCoreDataPropertiesSet = NSSet

extension Keyword {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Keyword> {
        return NSFetchRequest<Keyword>(entityName: "Keyword")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var word: String?
    @NSManaged public var voiceNote: VoiceNote?

}
