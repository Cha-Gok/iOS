import Core
import Foundation

/// 폴더 정보 업데이트 유스케이스 프로토콜.
/// 폴더 이름 변경 등 기존 폴더의 정보를 수정합니다.
public protocol UpdateFolderUseCase: Sendable {
    /// 폴더 정보를 업데이트합니다.
    /// - Parameter folder: 업데이트할 `Folder` 엔티티
    /// - Returns: 업데이트된 `Folder` 엔티티
    /// - Throws: 업데이트 실패 시
    func execute(_ folder: Folder) async throws(UpdateFolderUseCaseError) -> Folder
}

public struct DefaultUpdateFolderUseCase: UpdateFolderUseCase {
    private let repository: FolderRepository

    public init(repository: FolderRepository) {
        self.repository = repository
    }

    public func execute(_ folder: Folder) async throws(UpdateFolderUseCaseError) -> Folder {
        typealias UseCaseError = UpdateFolderUseCaseError
        if Task.isCancelled { throw UseCaseError.cancelled }

        let trimName: String = folder.name.trimmingCharacters(in: .whitespacesAndNewlines)

        // invalidName 유효성 검증
        guard !trimName.isEmpty, trimName == folder.name else {
            throw UseCaseError.invalidName
        }

        // 폴더 이름 제한
        guard trimName.count <= FolderConstants.maxNameLength else { throw UseCaseError.invalidLengthName }

        let updateFolder: Folder = .init(
            id: folder.id,
            path: folder.path,
            name: trimName,
            createdAt: folder.createdAt,
            content: folder.content,
            isDeletable: folder.isDeletable,
            deletedAt: folder.deletedAt
        )
        do {
            return try await repository.update(updateFolder)
        } catch {
            AppLogger.error(error)
            throw UseCaseError(error)
        }
    }
}
