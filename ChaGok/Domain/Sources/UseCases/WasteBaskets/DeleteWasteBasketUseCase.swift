import Foundation

/// 휴지통 삭제 유스케이스 프로토콜.
public protocol DeleteWasteBasketUseCase: Sendable {
    /// 삭제 방식(전체, 다수, 개별)에 따라 삭제를 수행합니다.
    /// - Parameter method: 삭제 방식 (`DeleteWasteBasketMethod` 참조)
    /// - Throws: 삭제 실패 또는 작업 취소 시 (`DeleteWasteBasketUseCaseError`)
    func execute(method: DeleteWasteBasketMethod) async throws(DeleteWasteBasketUseCaseError)
}

public struct DefaultDeleteWasteBasketUseCase: DeleteWasteBasketUseCase {

    private let repository: WasteBasketRepository

    public init(repository: WasteBasketRepository) {
        self.repository = repository
    }

    public func execute(method: DeleteWasteBasketMethod) async throws(DeleteWasteBasketUseCaseError) {
        typealias UseCaseError = DeleteWasteBasketUseCaseError
        if Task.isCancelled { throw UseCaseError.cancelled }
        do {
            switch method {
                case .all:
                    try await repository.allClear()
                case .multiple(let items):
                    try await repository.deleteAll(items: items)
                case .single(let item):
                    try await repository.delete(item: item)
            }
        } catch {
            switch error {
                case .cancelled:
                    throw UseCaseError.cancelled
                case .deleteFailed(let method):
                    throw UseCaseError.deleteFailed(method)
                case .unknown(let error):
                    throw UseCaseError.unknown(error)
            }
        }
    }
}
