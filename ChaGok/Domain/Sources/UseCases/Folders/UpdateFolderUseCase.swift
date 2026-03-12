import Foundation
import Core

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

        // 폴더 이름 제한
        guard folder.name.count <= 50 else { throw UseCaseError.invailedLengthName }

        // invalidName 유효성 검증
        guard !folder.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw UseCaseError.invalidName
        }

        do {
            return try await repository.update(folder)
        } catch {
            AppLogger.error(error)
            throw UseCaseError(error)
        }
    }

}
