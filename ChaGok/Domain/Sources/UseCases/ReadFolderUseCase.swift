import Foundation

/// 폴더 목록 조회 유스케이스 프로토콜.
/// CoreData에 저장된 모든 폴더 정보를 조회합니다.
public protocol ReadFolderUseCaseImpl {
    /// 모든 폴더 목록을 조회합니다.
    /// - Returns: 조회된 `Folder` 배열
    /// - Throws: 조회 실패 시
    func execute() async throws -> [Folder]
}

public struct ReadFolderUseCase: ReadFolderUseCaseImpl {

    private let repository: FolderRepository

    public init(repository: FolderRepository) {
        self.repository = repository
    }

    public func execute() async throws -> [Folder] {
        try await repository.fetchAll()
    }
}
