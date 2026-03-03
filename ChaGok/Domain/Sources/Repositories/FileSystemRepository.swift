import Foundation

/// 파일 시스템 관련 디렉토리 생성 및 조회를 담당하는 리포지토리 프로토콜.
/// 기본 폴더에 한해서만 Fetch 기능이 있습니다.
public protocol FileSystemRepository: Sendable {

    /// 루트 디렉토리 URL을 반환하거나, 존재하지 않으면 생성하여 반환합니다.
    /// - Returns: 루트 폴더 URL
    /// - Throws: 루트 폴더 생성 실패 시
    func fetchOrCreateRootDirectory() async throws -> URL

    /// 휴지통 폴더 URL을 반환하거나, 존재하지 않으면 생성하여 반환합니다.
    /// - Returns: 휴지통 폴더 URL
    /// - Throws: 휴지통 폴더 생성 실패 시
    func fetchOrCreateWasteBasketDirectory() async throws -> URL

    /// 기본 폴더도를 반환 합니다.
    /// fetchOrCreateRootDirectory 를 통해 반드시 루트 URL을 알아야 합니다.
    /// - Returns: Folder Entity 반환
    /// - Throws: 기본 폴더 생성 실패 시
    @discardableResult func fetchOrCreateBasicFolder() async throws -> Folder

}

/// 파일 시스템 내부 조작을 위한 내부 익스텐션 인터페이스.
internal protocol InternalFileSystemRepository: FileSystemRepository {

    /// 특정 URL에 디렉토리가 존재하는지 확인합니다.
    /// - Parameter url: 확인할 대상 경로
    /// - Returns: 폴더 존재 여부
    func directoryExists(at url: URL) -> Bool

}
