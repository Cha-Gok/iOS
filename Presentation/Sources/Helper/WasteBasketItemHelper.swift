import Domain
import Foundation

/// LibraryItem과 매칭 하기 위한 확장
extension WasteBasketItem {
    var id: UUID {
        switch self {
        case .folder(let obj): return obj.id
        case .voiceNote(let obj): return obj.id
        }
    }

    var toLibraryItem: LibraryItem {
        switch self {
        case .folder(let obj): return .folder(obj)
        case .voiceNote(let obj): return .voiceNote(obj)
        }
    }
}
