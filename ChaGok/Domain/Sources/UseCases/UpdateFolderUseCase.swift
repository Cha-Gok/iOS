import Foundation

/// 폴더 정보 업데이트 유스케이스 프로토콜.
/// 폴더 이름 변경 등 기존 폴더의 정보를 수정합니다.
public protocol UpdateFolderUseCaseImpl {
    /// 폴더 정보를 업데이트합니다.
    /// - Parameter folder: 업데이트할 `Folder` 엔티티
    /// - Returns: 업데이트된 `Folder` 엔티티
    /// - Throws: 업데이트 실패 시
    func execute(_ folder: Folder) async throws -> Folder
}

public struct UpdateFolderUseCase: UpdateFolderUseCaseImpl {

    private let repository: FolderRepository
    
    public init(repository: FolderRepository) {
        self.repository = repository
    }
    
    public func execute(_ folder: Folder) async throws -> Folder {
        try await repository.update(folder)
    }
}
