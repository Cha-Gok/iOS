import Foundation

/// 파일 시스템 관련 디렉토리 생성 및 조회를 담당하는 리포지토리 프로토콜.
/// 기본 폴더에 한해서만 Fetch 기능이 있습니다.
public protocol WorkSpaceRepository: Sendable {
    /// 루트 디렉토리 URL을 반환합니다
    /// - Returns: 루트 폴더 URL
    /// - Throws: 루트 URL 반환 실패 시
    func fetchRootURL() async throws(WorkSpaceRootURLRepositoryError) -> URL

    /// 기본 폴더를 반환 합니다.
    /// fetchOrCreateRootDirectory 를 통해 반드시 루트 URL을 알아야 합니다.
    /// - Returns: Folder Entity 반환
    /// - Throws: 기본 폴더 생성 실패 시
    @discardableResult
    func fetchOrCreateBasicFolder() async throws(WorkSpaceBasicFolderRepositoryError) -> Folder
}
