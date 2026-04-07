import Core
import Foundation

/// 폴더 생성 유스케이스 프로토콜.
/// FileManager를 통한 실제 디렉토리 생성과 CoreData 모델 저장을 요청합니다.
public protocol CreateFolderUseCase: Sendable {
    /// 새로운 폴더를 생성합니다.
    /// - Parameter name: 생성할 폴더의 이름
    /// - Returns: 생성된 `Folder` 엔티티
    /// - Throws: 폴더 생성 실패 시
    func execute(name: String) async throws(CreateFolderUseCaseError) -> Folder
}

public struct DefaultCreateFolderUseCase: CreateFolderUseCase {
    private let repository: FolderRepository

    public init(repository: FolderRepository) {
        self.repository = repository
    }

    public func execute(name: String) async throws(CreateFolderUseCaseError) -> Folder {
        if Task.isCancelled { throw .cancelled }

        let trimName: String = name.trimmingCharacters(in: .whitespacesAndNewlines)

        // invalidName 유효성 검증
        guard !trimName.isEmpty, trimName == name else {
            throw .invalidName
        }

        // 폴더 이름 제한
        guard trimName.count <= Policy.maxNameLength else { throw .invalidLengthName }

        let folder = Folder(
            name: trimName,
            isDeletable: trimName != Policy.defaultFolderName
        )

        do {
            return try await repository.create(folder)
        } catch {
            AppLogger.error(error)
            throw CreateFolderUseCaseError(error)
        }
    }
}
