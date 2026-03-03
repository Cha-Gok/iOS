import Foundation

/// 휴지통 내부 모델 - Folder 또는 VoiceNote가 될 수 있다.
public enum WasteBasketItem: Sendable {
    case folder(id: UUID)
    case voiceNote(id: UUID)
}

/// 휴지통 삭제 방식을 정의하는 열거형
public enum DeleteWasteBasketMethod: Sendable {
    /// 전체 삭제
    case all
    /// 다수 선택 삭제
    case multiple(items: [WasteBasketItem])
    /// 개별 삭제
    case single(item: WasteBasketItem)
}

/// 휴지통으로 이동 방식을 정의하는 열거 형
public enum MoveWasteBasketMethod: Sendable {
    /// 개별 이동
    case single(item: WasteBasketItem)
    /// 다수 선택 이동
    case multiple(items: [WasteBasketItem])
}
