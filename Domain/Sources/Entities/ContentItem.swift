import Foundation

public enum ContentItem: Hashable, Sendable {
    case folder(Folder)
    case voiceNote(VoiceNote)

    public var id: UUID {
        switch self {
        case .folder(let folder): return folder.id
        case .voiceNote(let voiceNote): return voiceNote.id
        }
    }

    public var createdAt: Date {
        switch self {
        case .folder(let folder): return folder.createdAt
        case .voiceNote(let voiceNote): return voiceNote.createdAt
        }
    }

    // 폴더는 updatedAt 개념이 없어 createdAt을 대리값으로 사용합니다.
    public var updatedAt: Date {
        switch self {
        case .folder(let folder): return folder.createdAt
        case .voiceNote(let voiceNote): return voiceNote.updatedAt
        }
    }

    public var deletedAt: Date? {
        switch self {
        case .folder(let folder): return folder.deletedAt
        case .voiceNote(let voiceNote): return voiceNote.deletedAt
        }
    }
}
