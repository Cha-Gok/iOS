import Foundation

public protocol FolderRepository: Sendable {
    /// 새로운 폴더를 생성합니다.
    func create(name: String) async throws -> Folder

    /// 모든 폴더 목록을 조회합니다.
    func fetchAll() async throws -> [Folder]

    /// 폴더 정보를 업데이트합니다. (이름 변경 등)
    func update(_ folder: Folder) async throws -> Folder

    /// 폴더를 삭제합니다.
    func delete(byId id: String) async throws
}
