import Foundation

/// 휴지통 내부 모델 - Folder 또는 VoiceNote가 될 수 있다.
public enum WasteBasketItem: Equatable, Sendable {
    case folder(id: UUID)
    case voiceNote(id: UUID)
}

/// 휴지통 삭제 방식을 정의하는 열거형
public enum DeleteWasteBasketMethod: Equatable, Sendable {
    /// 전체 삭제
    case all
    /// 다수 선택 삭제
    case multiple(items: [WasteBasketItem])
    /// 개별 삭제
    case single(item: WasteBasketItem)

    public var errorDescription: String {
        switch self {
        case .all:
            "휴지통 전체 삭제를 실패하였습니다"
        case .multiple:
            "휴지통 다수 선택 삭제를 실패하였습니다"
        case .single:
            "휴지통 개별 삭제를 실패하였습니다"
        }
    }
}

/// 휴지통으로 이동 방식을 정의하는 열거형
public enum MoveWasteBasketMethod: Equatable, Sendable {
    /// 개별 이동
    case single(item: WasteBasketItem)
    /// 다수 선택 이동
    case multiple(items: [WasteBasketItem])

    public var errorDescription: String {
        switch self {
        case .single:
            "휴지통 개별 이동을 실패하였습니다"
        case .multiple:
            "휴지통 다수 선택 이동을 실패하였습니다"
        }
    }
}
