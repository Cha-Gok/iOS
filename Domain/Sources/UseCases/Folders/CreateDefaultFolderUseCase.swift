import Core
import Foundation

/// 시스템 기본 폴더 생성 유스케이스 프로토콜.
/// 앱 최초 실행 시 삭제 불가능한 기본 폴더를 생성할 때 사용합니다.
public protocol CreateDefaultFolderUseCase: Sendable {
    /// 기본 폴더를 생성합니다.
    /// - Returns: 생성된 `Folder` 엔티티
    /// - Throws: 폴더 생성 실패 시 (`CreateFolderUseCaseError` 재사용)
    func execute() async throws(CreateFolderUseCaseError) -> Folder
}

public struct DefaultCreateDefaultFolderUseCase: CreateDefaultFolderUseCase {
    private let repository: FolderRepository

    public init(repository: FolderRepository) {
        self.repository = repository
    }

    public func execute() async throws(CreateFolderUseCaseError) -> Folder {
        if Task.isCancelled { throw .cancelled }

        let name = Policy.defaultFolderName
        let folder = Folder(
            name: name,
            isDeletable: false
        )

        do {
            return try await repository.create(folder)
        } catch {
            AppLogger.error(error)
            throw CreateFolderUseCaseError(error)
        }
    }
}
