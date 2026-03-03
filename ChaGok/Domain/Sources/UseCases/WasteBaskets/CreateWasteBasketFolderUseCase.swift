import Foundation

/// 휴지통 폴더의 URL을 반환하는 유즈케이스
public protocol CreateWasteBasketFolderUseCase: Sendable {
    /// 휴지통 폴더가 존재하는지 판단하고 반환합니다..
    /// - Parameter None
    /// - Returns: 생성된 휴지통 디렉토리 URL
    /// - Throws: 휴지통 폴더 생성 실패 시
    func execute() async throws -> URL
}

public struct DefaultCreateWasteBasketFolderUseCase: CreateWasteBasketFolderUseCase {

    private let repository: FileSystemRepository

    public init(repository: FileSystemRepository) {
        self.repository = repository
    }

    public func execute() async throws -> URL {
        return try await repository.fetchOrCreateWasteBasketDirectory()
    }
}
