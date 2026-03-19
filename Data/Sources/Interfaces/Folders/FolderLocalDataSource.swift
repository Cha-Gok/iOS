import Domain

/// Folders 도메인을 위한 로컬 데이터 소스 인터페이스입니다.
/// 이 인터페이스를 구현하는 객체는 스레드 안전성(Sendable)을 보장해야 합니다.
public protocol FolderLocalDataSource: Sendable {
    /// 새로운 폴더를 생성합니다.
    /// - Parameter name: 생성할 폴더의 이름
    /// - Returns: 생성된 폴더 도메인 모델
    /// - Throws: 폴더 생성 실패 시 에러 발생
    func create(name: String) async throws -> Folder

    /// 저장된 모든 폴더 목록을 조회합니다.
    /// - Returns: 폴더 도메인 모델 리스트
    /// - Throws: 폴더 조회 실패 시 에러 발생
    func fetch() async throws -> [Folder]

    /// 기존 폴더 정보를 업데이트합니다.
    /// - Parameter folder: 업데이트할 정보가 담긴 폴더 모델
    /// - Returns: 업데이트 완료된 폴더 도메인 모델
    /// - Throws: 폴더 업데이트 실패 시 에러 발생
    func update(_ folder: Folder) async throws -> Folder
}
