import Core
import Foundation

/// 휴지통 항목 복원 유스케이스 프로토콜.
public protocol RestoreWasteBasketUseCase: Sendable {
    /// 복원 방식(개별, 다수)에 따라 deletedAt을 nil로 복원합니다.
    /// - Parameter method: 복원 방식 (`RestoreWasteBasketMethod` 참조)
    /// - Throws: 복원 실패 또는 작업 취소 시 (`RestoreWasteBasketUseCaseError`)
    func execute(method: RestoreWasteBasketMethod) async throws(RestoreWasteBasketUseCaseError)
}

public struct DefaultRestoreWasteBasketUseCase: RestoreWasteBasketUseCase {
    private let repository: any WasteBasketRepository

    public init(repository: any WasteBasketRepository) {
        self.repository = repository
    }

    public func execute(method: RestoreWasteBasketMethod) async throws(RestoreWasteBasketUseCaseError) {
        if Task.isCancelled { throw .cancelled }
        do {
            switch method {
            case .single(let item):
                try await repository.restore(item: item)
            case .multiple(let items):
                try await repository.restoreAll(items: items)
            }
        } catch {
            AppLogger.error(error)
            throw RestoreWasteBasketUseCaseError(error)
        }
    }
}
