import Core
import Foundation

/// 폴더 생성·조회·수정을 담당하는 유스케이스 프로토콜.
@MainActor
public protocol FolderUseCase: Sendable {
    /// 새로운 폴더를 생성합니다.
    /// - Parameter name: 생성할 폴더의 이름
    /// - Returns: 생성된 `Folder` 엔티티
    func create(name: String) throws(FolderUseCaseError) -> Folder

    /// 앱 최초 실행 시 시스템이 사용하는 기본 폴더를 생성합니다.
    /// - Returns: 생성된 `Folder` 엔티티
    func createDefault() throws(FolderUseCaseError) -> Folder

    /// 앱 최초 실행 시 시스템이 사용하는 휴지통 폴더를 생성합니다.
    /// - Returns: 생성된 `Folder` 엔티티
    func createTrash() throws(FolderUseCaseError) -> Folder

    /// 삭제되지 않은 모든 폴더 목록을 조회합니다.
    /// - Returns: 조회된 `Folder` 배열
    func fetchAll() throws(FolderUseCaseError) -> [Folder]

    /// 기본 폴더(kind == .default)를 조회합니다.
    func fetchDefault() throws(FolderUseCaseError) -> Folder

    /// 휴지통 폴더(kind == .trash)를 조회합니다.
    func fetchTrash() throws(FolderUseCaseError) -> Folder

    /// 개인 폴더(kind == .custom) 목록을 조회합니다.
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
    func observeCustom() throws(FolderUseCaseError) -> AsyncStream<[Folder]>

    /// 휴지통에 있는(삭제된) 폴더 목록을 관찰합니다.
    func observeTrashed() throws(FolderUseCaseError) -> AsyncStream<[Folder]>

    /// 폴더를 휴지통으로 이동합니다. 안의 노트는 부모 폴더가 휴지통에 있는 형태로 cascade 표현됩니다.
    /// - Parameter folderID: 이동할 폴더의 UUID
    func moveToTrash(folderID: UUID) throws(FolderUseCaseError)

    /// 휴지통에 있는 폴더를 복원합니다. cascade로 함께 이동됐던 노트도 자연스럽게 복원됩니다.
    /// - Parameter folderID: 복원할 폴더의 UUID
    func restore(folderID: UUID) throws(FolderUseCaseError)

    /// 폴더를 영구 삭제합니다. 안의 모든 노트도 cascade로 삭제됩니다.
    /// - Parameter folderID: 삭제할 폴더의 UUID
    func delete(folderID: UUID) throws(FolderUseCaseError)
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

        let folder = Folder(name: trimName, kind: .custom)
        do {
            return try repository.create(folder)
        } catch {
            AppLogger.error(error)
            throw FolderUseCaseError(error)
        }
    }

    public func createDefault() throws(FolderUseCaseError) -> Folder {
        let folder = Folder(name: Policy.defaultFolderName, kind: .default)
        do {
            return try repository.create(folder)
        } catch {
            AppLogger.error(error)
            throw FolderUseCaseError(error)
        }
    }

    public func createTrash() throws(FolderUseCaseError) -> Folder {
        let folder = Folder(name: Policy.trashFolderName, kind: .trash)
        do {
            return try repository.create(folder)
        } catch {
            AppLogger.error(error)
            throw FolderUseCaseError(error)
        }
    }

    public func fetchDefault() throws(FolderUseCaseError) -> Folder {
        let folders: [Folder]
        do {
            folders = try repository.fetch(by: .default)
        } catch {
            AppLogger.error(error)
            throw FolderUseCaseError(error)
        }
        guard let folder = folders.first else { throw .notFound }
        return folder
    }

    public func fetchTrash() throws(FolderUseCaseError) -> Folder {
        let folders: [Folder]
        do {
            folders = try repository.fetch(by: .trash)
        } catch {
            AppLogger.error(error)
            throw FolderUseCaseError(error)
        }
        guard let folder = folders.first else { throw .notFound }
        return folder
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
            return folders.filter { $0.deletedAt == nil && $0.kind == .custom }
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

    public func observeCustom() throws(FolderUseCaseError) -> AsyncStream<[Folder]> {
        // Repository observe(by: .custom)의 predicate가 parentID == nil 조건을 포함하므로
        // 휴지통 이동된 폴더(parentID = trash.id)는 emit에서 자동 제외됨 → 추가 filter 불필요
        do {
            return try repository.observe(by: .custom)
        } catch {
            AppLogger.error(error)
            throw FolderUseCaseError(error)
        }
    }

    public func observeTrashed() throws(FolderUseCaseError) -> AsyncStream<[Folder]> {
        do {
            return try repository.observeTrashed()
        } catch {
            AppLogger.error(error)
            throw FolderUseCaseError(error)
        }
    }

    public func update(_ folder: Folder) throws(FolderUseCaseError) -> Folder {
        let trimName = folder.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimName.isEmpty, trimName == folder.name else { throw .invalidName }
        guard trimName.count <= Policy.maxNameLength else { throw .invalidLengthName }
        guard trimName != Policy.defaultFolderName else { throw .reservedName }

        var updateFolder = folder
        updateFolder.name = trimName
        do {
            return try repository.update(updateFolder)
        } catch {
            AppLogger.error(error)
            throw FolderUseCaseError(error)
        }
    }

    public func moveToTrash(folderID: UUID) throws(FolderUseCaseError) {
        let trash = try fetchTrash()

        let folder: Folder
        do {
            folder = try repository.fetch(by: folderID)
        } catch {
            AppLogger.error(error)
            throw FolderUseCaseError(error)
        }

        var trashed = folder
        trashed.parentID = trash.id
        trashed.deletedAt = .now

        do {
            _ = try repository.update(trashed)
        } catch {
            AppLogger.error(error)
            throw FolderUseCaseError(error)
        }
    }

    public func restore(folderID: UUID) throws(FolderUseCaseError) {
        let folder: Folder
        do {
            folder = try repository.fetch(by: folderID)
        } catch {
            AppLogger.error(error)
            throw FolderUseCaseError(error)
        }

        var restored = folder
        restored.parentID = nil
        restored.deletedAt = nil

        do {
            _ = try repository.update(restored)
        } catch {
            AppLogger.error(error)
            throw FolderUseCaseError(error)
        }
    }

    public func delete(folderID: UUID) throws(FolderUseCaseError) {
        do {
            try repository.delete(id: folderID)
        } catch {
            AppLogger.error(error)
            throw FolderUseCaseError(error)
        }
    }
}
