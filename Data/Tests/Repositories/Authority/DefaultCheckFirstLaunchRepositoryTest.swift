@testable import Data
import Domain
import XCTest

final class DefaultCheckFirstLaunchRepositoryTest: XCTestCase {}

// MARK: - 신규 사용자 판별 케이스

extension DefaultCheckFirstLaunchRepositoryTest {
    func test_신규사용자상태_최초실행확인시_true를반환한다() {
        let service = MockCheckFirstUserService()
        let sut = DefaultCheckFirstLaunchRepository(service: service)

        // Given
        service.setFirstUserResult(true)
        service.expectGetFirstUser(callCount: 1)
        service.expectSetUser(callCount: 1)

        // When
        let result = sut.checkAndMarkFirstLaunch()

        // Then
        XCTAssertTrue(result)
        service.verify()
    }

    func test_기존사용자상태_최초실행확인시_false를반환한다() {
        let service = MockCheckFirstUserService()
        let sut = DefaultCheckFirstLaunchRepository(service: service)

        // Given
        service.setFirstUserResult(false)
        service.expectGetFirstUser(callCount: 1)
        service.expectSetUser(callCount: 0)

        // When
        let result = sut.checkAndMarkFirstLaunch()

        // Then
        XCTAssertFalse(result)
        service.verify()
    }
}

// MARK: - 상태 변경 검증 케이스

extension DefaultCheckFirstLaunchRepositoryTest {
    func test_신규사용자상태_최초실행확인시_setUser가호출된다() {
        let service = MockCheckFirstUserService()
        let sut = DefaultCheckFirstLaunchRepository(service: service)

        // Given
        service.setFirstUserResult(true)
        service.expectSetUser(callCount: 1)

        // When
        _ = sut.checkAndMarkFirstLaunch()

        // Then
        service.verify()
    }

    func test_기존사용자상태_최초실행확인시_setUser가호출되지않는다() {
        let service = MockCheckFirstUserService()
        let sut = DefaultCheckFirstLaunchRepository(service: service)

        // Given
        service.setFirstUserResult(false)
        service.expectSetUser(callCount: 0)

        // When
        _ = sut.checkAndMarkFirstLaunch()

        // Then
        service.verify()
    }
}
