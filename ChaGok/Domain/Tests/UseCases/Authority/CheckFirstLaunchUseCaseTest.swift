import XCTest
@testable import Domain

final class CheckFirstLaunchUseCaseTest: XCTestCase {

    func test_동작_첫실행일때_리포지토리가True를반환하면_UseCase도True를반환한다() {
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

    func test_동작_기존사용자일때_리포지토리가False를반환하면_UseCase도False를반환한다() {
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
