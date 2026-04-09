import Core
import Foundation

/// 폴더 목록 조회 유스케이스 프로토콜.
/// CoreData에 저장된 모든 폴더 정보를 조회합니다.
public protocol FetchFolderUseCase: Sendable {
    /// 모든 폴더 목록을 조회합니다.
    /// - Returns: 조회된 `Folder` 배열
    /// - Throws: 조회 실패 시
    func fetchAll() async throws(FetchFolderUseCaseError) -> [Folder]

    func fetch(by id: UUID) async throws(FetchFolderUseCaseError) -> Folder
}

public struct DefaultFetchFolderUseCase: FetchFolderUseCase {
    private let repository: FolderRepository

    public init(repository: FolderRepository) {
        self.repository = repository
    }

    public func fetchAll() async throws(FetchFolderUseCaseError) -> [Folder] {
        if Task.isCancelled { throw .cancelled }
        do {
            return try await repository.fetchAll()
        } catch {
            AppLogger.error(error)
            throw FetchFolderUseCaseError(error)
        }
    }

    public func fetch(by id: UUID) async throws(FetchFolderUseCaseError) -> Folder {
        if Task.isCancelled { throw .cancelled }
        do {
            return try await repository.fetch(by: id)
        } catch {
            AppLogger.error(error)
            throw FetchFolderUseCaseError(error)
        }
    }
}
