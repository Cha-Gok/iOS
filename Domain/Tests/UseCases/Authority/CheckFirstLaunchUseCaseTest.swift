@testable import Domain
import XCTest

final class CheckFirstLaunchUseCaseTest: XCTestCase {}

// MARK: - 성공 케이스

extension CheckFirstLaunchUseCaseTest {
    func test_첫실행상태_앱실행여부확인시_True를반환하고첫실행으로마크한다() {
        // Given
        let repository = MockCheckFirstLaunchRepository()
        repository.setReturnValue(true)
        repository.expectCheckAndMarkFirstLaunch(callCount: 1)

        let useCase = DefaultCheckFirstLaunchUseCase(repository: repository)

        // When
        let result = useCase.execute()

        // Then
        XCTAssertTrue(result)
        repository.verify()
    }

    func test_기존사용자상태_앱실행여부확인시_False를반환하고첫실행으로마크하지않는다() {
        // Given
        let repository = MockCheckFirstLaunchRepository()
        repository.setReturnValue(false)
        repository.expectCheckAndMarkFirstLaunch(callCount: 1)

        let useCase = DefaultCheckFirstLaunchUseCase(repository: repository)

        // When
        let result = useCase.execute()

        // Then
        XCTAssertFalse(result)
        repository.verify()
    }
}
