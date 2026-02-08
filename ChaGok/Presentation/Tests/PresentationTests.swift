import Testing
@testable import Presentation

struct PresentationTests {

    @Test func contentViewCanBeCreated() async throws {
        // Presentation 레이어 테스트
        let view = ContentView()
        _ = view.body
    }
}
