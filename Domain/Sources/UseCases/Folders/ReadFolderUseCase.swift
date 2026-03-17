import Core
import Foundation

/// 폴더 목록 조회 유스케이스 프로토콜.
/// CoreData에 저장된 모든 폴더 정보를 조회합니다.
public protocol ReadFolderUseCase: Sendable {
    /// 모든 폴더 목록을 조회합니다.
    /// - Returns: 조회된 `Folder` 배열
    /// - Throws: 조회 실패 시
    func execute() async throws(ReadFolderUseCaseError) -> [Folder]
}

public struct DefaultReadFolderUseCase: ReadFolderUseCase {
    private let repository: FolderRepository

    public init(repository: FolderRepository) {
        self.repository = repository
    }

    public func execute() async throws(ReadFolderUseCaseError) -> [Folder] {
        typealias UseCaseError = ReadFolderUseCaseError
        if Task.isCancelled { throw UseCaseError.cancelled }
        do {
            return try await repository.fetchAll()
        } catch {
            AppLogger.error(error)
            throw UseCaseError(error)
        }
    }
}
