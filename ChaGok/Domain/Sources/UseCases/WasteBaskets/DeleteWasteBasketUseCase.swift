import Foundation

/// 휴지통 삭제 유스케이스 프로토콜.
public protocol DeleteWasteBasketUseCase: Sendable {
    /// 삭제 방식(전체, 다수, 개별)에 따라 삭제를 수행합니다.
    /// - Parameter method: 삭제 방식 및 대상 데이터
    /// - Returns: 성공 여부
    /// - Throws: 삭제 중 오류 발생 시
    func execute(method: DeleteWasteBasketMethod) async throws -> Bool
}

public struct DefaultDeleteWasteBasketUseCase: DeleteWasteBasketUseCase {

    private let repository: WasteBasketRepository

    public init(repository: WasteBasketRepository) {
        self.repository = repository
    }

    public func execute(method: DeleteWasteBasketMethod) async throws -> Bool {
        var result: Bool

        switch method {
            case .all:
                result = try await repository.allClear()
            case .multiple(let items):
                result = try await repository.deleteAll(items: items)
            case .single(let item):
                result = try await repository.delete(item: item)
        }

        return result
    }
}
