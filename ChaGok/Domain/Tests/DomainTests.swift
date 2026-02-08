import Testing
@testable import Domain

struct DomainTests {

    @Test func domainLayerExists() async throws {
        // Domain 레이어 테스트
        _ = ChaGokDomain.self
    }
}
