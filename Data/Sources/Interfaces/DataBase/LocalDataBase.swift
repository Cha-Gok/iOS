/// 로컬 데이터베이스를 위한 범용 인터페이스입니다.
/// 이 인터페이스를 구현하는 객체는 스레드 안전성(Sendable)을 보장해야 합니다.
public protocol LocalDataBase<Domain>: Sendable {
    /// 리포지토리가 다루는 도메인 모델 타입
    associatedtype Domain: Identifiable, Sendable where Domain.ID: Sendable

    /// 새로운 항목을 데이터베이스에 생성하고 저장합니다.
    /// - Parameter item: 저장할 도메인 데이터 모델
    /// - Returns: 저장 완료된 도메인 데이터 모델
    func create(_ item: Domain) async throws -> Domain

    /// 데이터베이스에 저장된 하나의 데이터를 조회합니다.
    /// - Parameter id: 특정 도메인 데이터 모델 ID
    /// - Returns: 조회 완료된 도메인 객체 모델
    func fetch(byId id: Domain.ID) async throws -> Domain

    /// 데이터베이스에 저장된 모든 데이터를 조회합니다.
    /// - Returns: 전체 도메인 데이터 리스트
    func fetchAll() async throws -> [Domain]

    /// 기존의 데이터를 업데이트합니다.
    /// - Parameter item: 업데이트할 정보가 담긴 도메인 데이터 모델
    /// - Returns: 업데이트 완료된 도메인 데이터 모델
    func update(_ item: Domain) async throws -> Domain

    /// 기존의 데이터를 데이터베이스에서 삭제합니다.
    /// - Parameter id: 삭제할 항목 정보를 담은 도메인 데이터 모델의 ID
    /// - Returns: 삭제된 도메인 데이터 모델
    func delete(byId id: Domain.ID) async throws -> Domain
}
