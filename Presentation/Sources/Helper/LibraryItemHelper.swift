import Domain
import Foundation

extension LibraryItem {
    var createdAt: Date {
        switch self {
        case .folder(let obj): return obj.createdAt
        case .voiceNote(let obj): return obj.createdAt
        }
    }

    var updatedAt: Date {
        switch self {
        case .folder(let obj): return obj.createdAt // 폴더는 updatedAt이 없으므로 createdAt 사용
        case .voiceNote(let obj): return obj.updatedAt
        }
    }

    var toWasteBasketItem: WasteBasketItem {
        switch self {
        case .folder(let folder): return .folder(obj: folder)
        case .voiceNote(let voiceNote): return .voiceNote(obj: voiceNote)
        }
    }
}
