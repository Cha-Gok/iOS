@testable import Data
import Domain
import XCTest

final class DefaultCheckFirstLaunchRepositoryTest: XCTestCase {}

// MARK: - 신규 사용자 판별 케이스

extension DefaultCheckFirstLaunchRepositoryTest {
    func test_신규사용자상태_최초실행확인시_true를반환한다() {
        let store = MockKeyValueStoreService()
        let sut = DefaultCheckFirstLaunchRepository(store: store)

        // Given: isExistingUserKey 미설정 → bool(forKey:) == false → isFirstLaunch == true

        // When
        let result = sut.checkAndMarkFirstLaunch()

        // Then
        XCTAssertTrue(result)
    }

    func test_기존사용자상태_최초실행확인시_false를반환한다() {
        let store = MockKeyValueStoreService()
        // Given: 기존 사용자 — isExistingUserKey 사전 설정
        store.set(true, forKey: Policy.isExistingUserKey)
        let sut = DefaultCheckFirstLaunchRepository(store: store)

        // When
        let result = sut.checkAndMarkFirstLaunch()

        // Then
        XCTAssertFalse(result)
    }
}

// MARK: - 상태 변경 검증 케이스

extension DefaultCheckFirstLaunchRepositoryTest {
    func test_신규사용자상태_최초실행확인시_isExistingUser키가true로설정된다() {
        let store = MockKeyValueStoreService()
        let sut = DefaultCheckFirstLaunchRepository(store: store)

        // Given: isExistingUserKey 미설정

        // When
        _ = sut.checkAndMarkFirstLaunch()

        // Then
        XCTAssertTrue(store.bool(forKey: Policy.isExistingUserKey) == true)
    }

    func test_기존사용자상태_최초실행확인시_isExistingUser키가변경되지않는다() {
        let store = MockKeyValueStoreService()
        // Given: 기존 사용자
        store.set(true, forKey: Policy.isExistingUserKey)
        let sut = DefaultCheckFirstLaunchRepository(store: store)

        // When
        _ = sut.checkAndMarkFirstLaunch()

        // Then: 값은 여전히 true (변경 없음)
        XCTAssertTrue(store.bool(forKey: Policy.isExistingUserKey) == true)
    }
}

// MARK: - 단순 조회 (Getter) 검증 케이스

extension DefaultCheckFirstLaunchRepositoryTest {
    func test_신규사용자상태_조회시_true를반환하고_상태는변경하지않는다() {
        let store = MockKeyValueStoreService()
        let sut = DefaultCheckFirstLaunchRepository(store: store)

        // Given: isExistingUserKey 미설정

        // When
        let result = sut.checkIsFirstLaunch()

        // Then
        XCTAssertTrue(result)
        XCTAssertFalse(store.bool(forKey: Policy.isExistingUserKey) == true)
    }

    func test_기존사용자상태_조회시_false를반환하고_상태는변경하지않는다() {
        let store = MockKeyValueStoreService()
        // Given: 기존 사용자
        store.set(true, forKey: Policy.isExistingUserKey)
        let sut = DefaultCheckFirstLaunchRepository(store: store)

        // When
        let result = sut.checkIsFirstLaunch()

        // Then
        XCTAssertFalse(result)
        XCTAssertTrue(store.bool(forKey: Policy.isExistingUserKey) == true)
    }
}
