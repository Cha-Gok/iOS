import Core
import Foundation

/// 폴더 생성·조회·수정을 담당하는 유스케이스 프로토콜.
@MainActor
public protocol FolderUseCase: Sendable {
    /// 새로운 폴더를 생성합니다.
    /// - Parameter name: 생성할 폴더의 이름
    /// - Returns: 생성된 `Folder` 엔티티
    func create(name: String) throws(FolderUseCaseError) -> Folder

    /// 앱 최초 실행 시 삭제 불가능한 기본 폴더를 생성합니다.
    /// - Returns: 생성된 `Folder` 엔티티
    func createDefault() throws(FolderUseCaseError) -> Folder

    /// 삭제되지 않은 모든 폴더 목록을 조회합니다.
    /// - Returns: 조회된 `Folder` 배열
    func fetchAll() throws(FolderUseCaseError) -> [Folder]

    /// 기본 폴더(isDeletable == false)를 제외한 개인 폴더 목록을 조회합니다.
    /// - Returns: 삭제 가능한 `Folder` 배열
    func fetchDeletableFolders() throws(FolderUseCaseError) -> [Folder]

    /// ID로 특정 폴더를 조회합니다.
    /// - Parameter id: 조회할 폴더의 UUID
    /// - Returns: 조회된 `Folder` 엔티티
    func fetch(by id: UUID) throws(FolderUseCaseError) -> Folder

    /// 폴더 정보를 업데이트합니다.
    /// - Parameter folder: 업데이트할 `Folder` 엔티티
    /// - Returns: 업데이트된 `Folder` 엔티티
    func update(_ folder: Folder) throws(FolderUseCaseError) -> Folder

    /// 개인 폴더 목록을 관찰합니다. 첫 emit은 현재 상태이며, 이후 변경 시 재emit됩니다.
    func observeDeletableFolders() throws(FolderUseCaseError) -> AsyncStream<[Folder]>
}

public struct DefaultFolderUseCase: FolderUseCase {
    private let repository: any FolderRepository

    public init(repository: any FolderRepository) {
        self.repository = repository
    }

    public func create(name: String) throws(FolderUseCaseError) -> Folder {
        let trimName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimName.isEmpty, trimName == name else { throw .invalidName }
        guard trimName.count <= Policy.maxNameLength else { throw .invalidLengthName }
        guard trimName != Policy.defaultFolderName else { throw .reservedName }

        let folder = Folder(name: trimName, isDeletable: true)
        do {
            return try repository.create(folder)
        } catch {
            AppLogger.error(error)
            throw FolderUseCaseError(error)
        }
    }

    public func createDefault() throws(FolderUseCaseError) -> Folder {
        let folder = Folder(name: Policy.defaultFolderName, isDeletable: false)
        do {
            return try repository.create(folder)
        } catch {
            AppLogger.error(error)
            throw FolderUseCaseError(error)
        }
    }

    public func fetchAll() throws(FolderUseCaseError) -> [Folder] {
        do {
            let folders = try repository.fetchAll()
            return folders.filter { $0.deletedAt == nil }
        } catch {
            AppLogger.error(error)
            throw FolderUseCaseError(error)
        }
    }

    public func fetchDeletableFolders() throws(FolderUseCaseError) -> [Folder] {
        do {
            let folders = try repository.fetchAll()
            return folders.filter { $0.deletedAt == nil && $0.isDeletable }
        } catch {
            AppLogger.error(error)
            throw FolderUseCaseError(error)
        }
    }

    public func fetch(by id: UUID) throws(FolderUseCaseError) -> Folder {
        do {
            return try repository.fetch(by: id)
        } catch {
            AppLogger.error(error)
            throw FolderUseCaseError(error)
        }
    }

    public func observeDeletableFolders() throws(FolderUseCaseError) -> AsyncStream<[Folder]> {
        let stream: AsyncStream<[Folder]>
        do {
            stream = try repository.observeAll()
        } catch {
            AppLogger.error(error)
            throw FolderUseCaseError(error)
        }
        return AsyncStream { continuation in
            let task = Task { @MainActor in
                for await folders in stream {
                    let deletable = folders.filter { $0.deletedAt == nil && $0.isDeletable }
                    continuation.yield(deletable)
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    public func update(_ folder: Folder) throws(FolderUseCaseError) -> Folder {
        let trimName = folder.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimName.isEmpty, trimName == folder.name else { throw .invalidName }
        guard trimName.count <= Policy.maxNameLength else { throw .invalidLengthName }
        guard trimName != Policy.defaultFolderName else { throw .reservedName }

        let updateFolder = Folder(
            id: folder.id,
            name: trimName,
            createdAt: folder.createdAt,
            content: folder.content,
            isDeletable: folder.isDeletable,
            deletedAt: folder.deletedAt
        )
        do {
            return try repository.update(updateFolder)
        } catch {
            AppLogger.error(error)
            throw FolderUseCaseError(error)
        }
    }
}
