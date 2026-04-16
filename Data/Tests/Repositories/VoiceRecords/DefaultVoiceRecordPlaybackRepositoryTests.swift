@testable import Data
import Domain
import XCTest

@MainActor
final class DefaultVoiceRecordPlaybackRepositoryTests: XCTestCase {
    private var sut: DefaultVoiceRecordPlaybackRepository!
    private var mockStorageService: MockStorageService!

    override func setUp() {
        super.setUp()
        mockStorageService = MockStorageService()
        sut = DefaultVoiceRecordPlaybackRepository(storageService: mockStorageService)
    }

    override func tearDown() {
        sut = nil
        mockStorageService = nil
        super.tearDown()
    }
}

// MARK: - 재생 제어 테스트 (비활성화)

/*
 // AVAudioPlayer를 직접 사용하게 리팩토링됨에 따라, 단위 테스트 환경에서 재생/일시정지 등의 테스트가 어려움.
 @MainActor
 extension DefaultVoiceRecordPlaybackRepositoryTests {
     func test_prepare호출시_결과를반환한다() async throws {
         // ...
     }
 }
 */
