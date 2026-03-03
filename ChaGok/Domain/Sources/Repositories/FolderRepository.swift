import Foundation

/// 폴더(Folder) 엔티티의 CRUD를 담당하는 리포지토리 프로토콜.
public protocol FolderRepository: Sendable {
    /// 새로운 폴더를 생성합니다.
    /// - Parameter name: 생성할 폴더의 이름
    /// - Returns: 생성된 폴더 엔티티
    /// - Throws: 폴더 생성 실패 시
    func create(name: String) async throws -> Folder

    /// 모든 폴더 목록을 조회합니다.
    /// - Returns: 조회된 폴더 목록
    /// - Throws: 조회 실패 시
    func fetchAll() async throws -> [Folder]

    /// 폴더 정보를 업데이트합니다. (이름 변경 등)
    /// - Parameter folder: 업데이트할 폴더 엔티티
    /// - Returns: 업데이트된 폴더 엔티티
    /// - Throws: 업데이트 실패 시
    func update(_ folder: Folder) async throws -> Folder

    /// 특정 폴더를 삭제합니다.
    /// - Parameter id: 삭제할 폴더의 ID
    /// - Throws: 삭제 실패 시
    func delete(byId id: UUID) async throws
}
