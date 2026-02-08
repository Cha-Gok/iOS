import Testing
@testable import Data

struct DataTests {

    @Test func dataLayerExists() async throws {
        // Data 레이어 테스트
        _ = ChaGokData.self
    }
}
