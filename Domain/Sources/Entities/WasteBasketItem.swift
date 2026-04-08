import Foundation

public enum WasteBasketItem: Equatable, Hashable, Sendable {
    case folder(id: UUID)
    case voiceNote(id: UUID)
}

public enum DeleteWasteBasketMethod: Equatable, Sendable {
    case all
    case multiple(items: [WasteBasketItem])
    case single(item: WasteBasketItem)
}

public enum MoveWasteBasketMethod: Equatable, Sendable {
    case single(item: WasteBasketItem)
    case multiple(items: [WasteBasketItem])
}
