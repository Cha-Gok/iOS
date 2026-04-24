import Foundation

/// 폴더(Folder) 엔티티의 CRU 를 담당하는 리포지토리 프로토콜.
@MainActor
public protocol FolderRepository: Sendable {
    /// 새로운 폴더를 생성합니다.
    /// - Parameter folder: 생성할 폴더 엔티티
    /// - Returns: 생성된 폴더 엔티티
    /// - Throws: `FolderRepositoryError.createFailed`, `.duplicateName` 등
    func create(_ folder: Folder) throws(FolderRepositoryError) -> Folder

    /// 모든 폴더 목록을 조회합니다.
    /// - Returns: 조회된 폴더 목록
    /// - Throws: `FolderRepositoryError.fetchFailed` 등
    func fetchAll() throws(FolderRepositoryError) -> [Folder]

    /// ID로 특정 폴더를 조회합니다.
    /// - Parameter id: 조회할 폴더의 UUID
    /// - Returns: 조회된 폴더 엔티티
    /// - Throws: `FolderRepositoryError.notFound`, `.fetchFailed` 등
    func fetch(by id: UUID) throws(FolderRepositoryError) -> Folder

    /// 폴더 정보를 업데이트합니다. (이름 변경 등)
    /// - Parameter folder: 업데이트할 폴더 엔티티
    /// - Returns: 업데이트된 폴더 엔티티
    /// - Throws: `FolderRepositoryError.updateFailed`, `.notFound`, `.duplicateName` 등
    func update(_ folder: Folder) throws(FolderRepositoryError) -> Folder

    /// 모든 폴더 목록을 관찰합니다. 첫 emit은 현재 상태이며, 이후 변경 시 재emit됩니다.
    func observeAll() throws(FolderRepositoryError) -> AsyncStream<[Folder]>
}
