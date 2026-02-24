import Foundation

public struct Folder {
    public let id: String
    public let path: URL
    public let name: String
    public let createdAt: Date
    public let content: [VoiceNote]
    
    public init(
        id: String,
        path: URL,
        name: String,
        createdAt: Date,
        content: [VoiceNote]
    ) {
        self.id = id
        self.path = path
        self.name = name
        self.createdAt = createdAt
        self.content = content
    }
}
