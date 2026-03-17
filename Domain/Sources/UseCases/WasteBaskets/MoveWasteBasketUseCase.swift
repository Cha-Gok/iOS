import Core
import Foundation

/// 휴지통으로 폴더 또는 파일을 이동시키는 유즈케이스
public protocol MoveWasteBasketUseCase: Sendable {
    /// 개별 Item 또는 다수의 Item을 휴지통으로 이동시킵니다.
    /// - Parameter method: 이동 방식 (`MoveWasteBasketMethod` 참조)
    /// - Throws: 이동 실패 또는 작업 취소 시 (`MoveWasteBasketUseCaseError`)
    func execute(method: MoveWasteBasketMethod) async throws(MoveWasteBasketUseCaseError)
}

public struct DefaultMoveWasteBasketUseCase: MoveWasteBasketUseCase {
    private let repository: WasteBasketRepository

    public init(repository: WasteBasketRepository) {
        self.repository = repository
    }

    public func execute(method: MoveWasteBasketMethod) async throws(MoveWasteBasketUseCaseError) {
        if Task.isCancelled { throw .cancelled }
        do {
            switch method {
            case .multiple(let items):
                try await repository.moveAllToWasteBasket(items: items)
            case .single(let item):
                try await repository.moveToWasteBasket(item: item)
            }
        } catch {
            AppLogger.error(error)
            throw MoveWasteBasketUseCaseError(error)
        }
    }
}
