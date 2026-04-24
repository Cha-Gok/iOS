import Foundation

public enum WasteBasketItem: Equatable, Hashable, Sendable {
    case folder(obj: Folder)
    case voiceNote(obj: VoiceNote)
}
