import Foundation

/// 폴더 삭제 유스케이스 프로토콜.
/// 지정한 폴더의 실제 디렉토리와 CoreData 모델을 삭제합니다.
public protocol DeleteFolderUseCase: Sendable {
    /// ID로 특정 폴더를 삭제합니다.
    /// - Parameter id: 삭제할 폴더의 ID
    /// - Throws: 폴더 삭제 실패 시
    func execute(byId id: UUID) async throws
}

public struct DefaultDeleteFolderUseCase: DeleteFolderUseCase {

    private let repository: FolderRepository

    public init(repository: FolderRepository) {
        self.repository = repository
    }

    public func execute(byId id: UUID) async throws {
        try await repository.delete(byId: id)
    }
}
