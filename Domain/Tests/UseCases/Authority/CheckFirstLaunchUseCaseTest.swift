@testable import Domain
import Core
import DomainTesting
import XCTest

final class CheckFirstLaunchUseCaseTest: XCTestCase {}

extension CheckFirstLaunchUseCaseTest {
    func test_신규사용자상태_단순조회시_True를반환하고_상태변경메서드는호출하지않는다() {
        let authorityRepository = MockCheckFirstLaunchRepository()
        let sut = DefaultCheckFirstLaunchUseCase(repository: authorityRepository)

        authorityRepository.setReturnValue(true)
        authorityRepository.expectCheckIsFirstLaunch(callCount: 1)
        authorityRepository.expectCheckAndMarkFirstLaunch(callCount: 0)

        let result = sut.checkIsFirstLaunch()

        XCTAssertTrue(result)
        authorityRepository.verify()
    }

    func test_기존사용자상태_단순조회시_False를반환하고_상태변경메서드는호출하지않는다() {
        let authorityRepository = MockCheckFirstLaunchRepository()
        let sut = DefaultCheckFirstLaunchUseCase(repository: authorityRepository)

        authorityRepository.setReturnValue(false)
        authorityRepository.expectCheckIsFirstLaunch(callCount: 1)
        authorityRepository.expectCheckAndMarkFirstLaunch(callCount: 0)

        let result = sut.checkIsFirstLaunch()

        XCTAssertFalse(result)
        authorityRepository.verify()
    }
}

extension CheckFirstLaunchUseCaseTest {
    func test_첫실행상태_완료처리시_True를반환하고첫실행마킹을수행한다() {
        let authorityRepository = MockCheckFirstLaunchRepository()
        let sut = DefaultCompleteFirstLaunchUseCase(repository: authorityRepository)

        authorityRepository.setReturnValue(true)
        authorityRepository.expectCheckAndMarkFirstLaunch(callCount: 1)
        authorityRepository.expectCheckIsFirstLaunch(callCount: 0)

        let result = sut.execute()

        XCTAssertTrue(result)
        authorityRepository.verify()
    }

    func test_기존사용자상태_완료처리시_False를반환하고첫실행마킹메서드를호출한다() {
        let authorityRepository = MockCheckFirstLaunchRepository()
        let sut = DefaultCompleteFirstLaunchUseCase(repository: authorityRepository)

        authorityRepository.setReturnValue(false)
        authorityRepository.expectCheckAndMarkFirstLaunch(callCount: 1)
        authorityRepository.expectCheckIsFirstLaunch(callCount: 0)

        let result = sut.execute()

        XCTAssertFalse(result)
        authorityRepository.verify()
    }
}
