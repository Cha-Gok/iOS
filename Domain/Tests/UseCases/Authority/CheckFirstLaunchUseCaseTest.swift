@testable import Domain
import Core
import XCTest

final class CheckFirstLaunchUseCaseTest: XCTestCase {}

// MARK: - 성공 케이스

extension CheckFirstLaunchUseCaseTest {
    func test_첫실행상태_앱실행여부확인시_True를반환하고첫실행으로마크한다() {
        let authorityRepository = MockCheckFirstLaunchRepository()
        let sut = DefaultCheckFirstLaunchUseCase(repository: authorityRepository)

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
        let authorityRepository = MockCheckFirstLaunchRepository()
        let sut = DefaultCheckFirstLaunchUseCase(repository: authorityRepository)

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
