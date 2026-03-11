import Foundation
import Core

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
        typealias UseCaseError = CreateFolderUseCaseError
        if Task.isCancelled { throw UseCaseError.cancelled }

        // invalidName 유효성 검증
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw UseCaseError.invalidName
        }

        do {
            return try await repository.create(name: name)
        } catch {
            AppLogger.error(error)
            throw UseCaseError(error)
        }
    }
}
