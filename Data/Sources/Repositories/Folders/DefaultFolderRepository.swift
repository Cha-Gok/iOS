import Core
import Domain

/// Folders 도메인을 위한 리포지토리 실구현체입니다.
/// 이제 리포지토리는 Core Data 엔진을 직접 관리하지 않고, 추상화된 `LocalDataBase`에 의존합니다.
actor DefaultFolderRepository: FolderRepository {
    private let database: any LocalDataBase<Folder>

    init(database: any LocalDataBase<Folder>) {
        self.database = database
    }

    func create(name: String) async throws(FolderRepositoryError) -> Folder {
        if Task.isCancelled { throw .cancelled }

        do {
            // Folder 생성을 위해 기본값들로 초기화 (path 등)
            let folder = Folder(path: .applicationSupportDirectory, name: name)
            return try await database.create(folder)
        } catch {
            AppLogger.error(error)
            throw .createFailed
        }
    }

    func fetchAll() async throws(FolderRepositoryError) -> [Folder] {
        if Task.isCancelled { throw .cancelled }

        do {
            return try await database.fetch()
        } catch {
            AppLogger.error(error)
            throw .fetchFailed
        }
    }

    func update(_ folder: Folder) async throws(FolderRepositoryError) -> Folder {
        if Task.isCancelled { throw .cancelled }

        do {
            return try await database.update(folder)
        } catch {
            AppLogger.error(error)
            throw .updateFailed
        }
    }
}
