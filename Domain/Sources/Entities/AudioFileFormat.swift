import Foundation

public enum AudioFileFormat: String, CaseIterable, Sendable {
    case m4a
    case wav
    case mp3
    case caf
    case aac
    case aiff
    case aif

    public init?(extension: String) {
        self.init(rawValue: `extension`.lowercased())
    }
}
