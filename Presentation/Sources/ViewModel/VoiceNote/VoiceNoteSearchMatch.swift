import Foundation

public struct VoiceNoteSearchMatch: Hashable, Sendable {
    public enum Location: Hashable, Sendable {
        case keyPoint(index: Int)
        case keyword(index: Int)
        case script(sectionIndex: Int)
    }

    public let location: Location
    public let range: NSRange

    public init(location: Location, range: NSRange) {
        self.location = location
        self.range = range
    }
}
