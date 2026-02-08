import Testing
@testable import Core

struct CoreTests {

    @Test func coreLayerExists() async throws {
        // Core 레이어 테스트
        _ = ChaGokCore.self
    }
}
