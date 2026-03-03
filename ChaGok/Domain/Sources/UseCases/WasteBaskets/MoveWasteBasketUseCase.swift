import Foundation

/// 휴지통으로 폴더 또는 파일을 이동시키는 유즈케이스
public protocol MoveWasteBasketUseCase: Sendable {
    /// 개별 Item 또는 다수의 Item을 휴지통으로 이동시킵니다.
    /// - Parameter method: 이동 방식 및 대상 데이터
    /// - Returns: 성공 여부
    func execute(method: MoveWasteBasketMethod) async throws
}

public struct DefaultMoveWasteBasketUseCase: MoveWasteBasketUseCase {
    private let repository: WasteBasketRepository

    public init(repository: WasteBasketRepository) {
        self.repository = repository
    }

    public func execute(method: MoveWasteBasketMethod) async throws {
        switch method {
            case .multiple(let items):
                return try await repository.moveAllToWasteBasket(items: items)
            case .single(let item):
                return try await repository.moveToWasteBasket(item: item)
        }
    }
}
