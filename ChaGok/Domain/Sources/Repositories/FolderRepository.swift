import Foundation

/// 폴더의 생성, 조회, 수정, 삭제(CRUD)를 담당하는 리포지토리 프로토콜.
public protocol FolderRepository: Sendable {
    /// 새로운 폴더를 생성합니다.
    /// - Parameter name: 생성할 폴더의 이름
    /// - Returns: 생성된 폴더 객체 (`Folder`)
    /// - Throws: 폴더 생성 실패 시 (`FolderError`)
    func create(name: String) async throws -> Folder

    /// 모든 폴더 목록을 조회합니다.
    /// - Returns: 저장된 모든 폴더 배열 (`[Folder]`)
    /// - Throws: 폴더 조회 실패 시 (`FolderError`)
    func fetchAll() async throws -> [Folder]

    /// 폴더 정보를 업데이트합니다. (이름 변경 등)
    /// - Parameter folder: 업데이트할 정보를 담은 폴더 객체
    /// - Returns: 업데이트된 폴더 객체 (`Folder`)
    /// - Throws: 폴더 업데이트 실패 시 (`FolderError`)
    func update(_ folder: Folder) async throws -> Folder

    /// 특정 ID를 가진 폴더를 삭제합니다.
    /// - Parameter id: 삭제할 폴더의 UUID
    /// - Throws: 폴더 삭제 실패 시 (`FolderError`)
    func delete(byId id: UUID) async throws
}
