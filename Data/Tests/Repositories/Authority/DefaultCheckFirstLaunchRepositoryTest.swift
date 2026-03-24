@testable import Data
import Domain
import XCTest

final class DefaultCheckFirstLaunchRepositoryTest: XCTestCase {}

// MARK: - 신규 사용자 판별 케이스

extension DefaultCheckFirstLaunchRepositoryTest {
    func test_신규사용자상태_최초실행확인시_true를반환한다() {
        let service = MockFirstLaunchService()
        let sut = DefaultCheckFirstLaunchRepository(service: service)

        // Given
        service.setIsFirstLaunchResult(true)
        service.expectIsFirstLaunch(callCount: 1)
        service.expectMarkAsLaunched(callCount: 1)

        // When
        let result = sut.checkAndMarkFirstLaunch()

        // Then
        XCTAssertTrue(result)
        service.verify()
    }

    func test_기존사용자상태_최초실행확인시_false를반환한다() {
        let service = MockFirstLaunchService()
        let sut = DefaultCheckFirstLaunchRepository(service: service)

        // Given
        service.setIsFirstLaunchResult(false)
        service.expectIsFirstLaunch(callCount: 1)
        service.expectMarkAsLaunched(callCount: 0)

        // When
        let result = sut.checkAndMarkFirstLaunch()

        // Then
        XCTAssertFalse(result)
        service.verify()
    }
}

// MARK: - 상태 변경 검증 케이스

extension DefaultCheckFirstLaunchRepositoryTest {
    func test_신규사용자상태_최초실행확인시_markAsLaunched가호출된다() {
        let service = MockFirstLaunchService()
        let sut = DefaultCheckFirstLaunchRepository(service: service)

        // Given
        service.setIsFirstLaunchResult(true)
        service.expectMarkAsLaunched(callCount: 1)

        // When
        _ = sut.checkAndMarkFirstLaunch()

        // Then
        service.verify()
    }

    func test_기존사용자상태_최초실행확인시_markAsLaunched가호출되지않는다() {
        let service = MockFirstLaunchService()
        let sut = DefaultCheckFirstLaunchRepository(service: service)

        // Given
        service.setIsFirstLaunchResult(false)
        service.expectMarkAsLaunched(callCount: 0)

        // When
        _ = sut.checkAndMarkFirstLaunch()

        // Then
        service.verify()
    }
}
