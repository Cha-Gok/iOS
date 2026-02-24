import Foundation

/// 폴더 생성 유스케이스 프로토콜.
/// FileManager를 통한 실제 디렉토리 생성과 CoreData 모델 저장을 요청합니다.
public protocol CreateFolderUseCaseImpl {
    /// 새로운 폴더를 생성합니다.
    /// - Parameter name: 생성할 폴더의 이름
    /// - Returns: 생성된 `Folder` 엔티티
    /// - Throws: 폴더 생성 실패 시
    func execute(name: String) async throws -> Folder
}

public struct CreateFolderUseCase: CreateFolderUseCaseImpl {

    private let repository: FolderRepository

    public init(repository: FolderRepository) {
        self.repository = repository
    }

    public func execute(name: String) async throws -> Folder {
        try await repository.create(name: name)
    }
}
