import Core
import Foundation

/// 휴지통 폴더의 Item을 조회하는 유즈케이스
public protocol FetchWasteBasketFolderUseCase: Sendable {
    /// 휴지통 내부 Folder, VoiceNote를 조회합니다.
    /// - Parameter None
    /// - Returns: (VoiceNote 또는 Folder) 배열
    /// - Throws: FetchWasteBasketFolderUseCaseError (조회 실패 시)
    func execute() async throws(FetchWasteBasketFolderUseCaseError) -> [WasteBasketItem]
}

public struct DefaultFetchWasteBasketFolderUseCase: FetchWasteBasketFolderUseCase {
    private let repository: WasteBasketRepository

    public init(repository: WasteBasketRepository) {
        self.repository = repository
    }

    public func execute() async throws(FetchWasteBasketFolderUseCaseError) -> [WasteBasketItem] {
        if Task.isCancelled { throw .cancelled }
        do {
            return try await repository.fetchAll()
        } catch {
            AppLogger.error(error)
            throw FetchWasteBasketFolderUseCaseError(error)
        }
    }
}
