@testable import Domain
import Core
import XCTest

final class CheckFirstLaunchUseCaseTest: XCTestCase {
    private var authorityRepository: MockCheckFirstLaunchRepository!
    private var sut: DefaultCheckFirstLaunchUseCase!

    override func setUp() {
        super.setUp()
        authorityRepository = MockCheckFirstLaunchRepository()
        sut = DefaultCheckFirstLaunchUseCase(repository: authorityRepository)
    }

    override func tearDown() {
        authorityRepository = nil
        sut = nil
        super.tearDown()
    }
}

// MARK: - 성공 케이스

extension CheckFirstLaunchUseCaseTest {
    func test_첫실행상태_앱실행여부확인시_True를반환하고첫실행으로마크한다() {
        // Given
        authorityRepository.setReturnValue(true)
        authorityRepository.expectCheckAndMarkFirstLaunch(callCount: 1)

        // When
        let result = sut.execute()

        // Then
        XCTAssertTrue(result)
        authorityRepository.verify()
    }

    func test_기존사용자상태_앱실행여부확인시_False를반환하고첫실행으로마크하지않는다() {
        // Given
        authorityRepository.setReturnValue(false)
        authorityRepository.expectCheckAndMarkFirstLaunch(callCount: 1)

        // When
        let result = sut.execute()

        // Then
        XCTAssertFalse(result)
        authorityRepository.verify()
    }
}
