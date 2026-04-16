@testable import Data
import Domain
import XCTest

final class DefaultLanguageRepositoryTest: XCTestCase {}

// MARK: - 조회 케이스

extension DefaultLanguageRepositoryTest {
    func test_기존언어데이터가있는상태_언어조회시_저장된언어를반환한다() {
        let store = MockKeyValueStoreService()
        // Given: 저장된 언어 ko
        store.set("ko", forKey: Policy.appSelectedLanguageKey)
        let sut = DefaultLanguageRepository(store: store)

        // When
        let language = sut.fetchLanguage()

        // Then
        XCTAssertEqual(language, .ko)
    }

    func test_저장된언어데이터가없는상태_언어조회시_기본값인한국어를반환한다() {
        let store = MockKeyValueStoreService()
        // Given: appSelectedLanguageKey 미설정 → string(forKey:) == nil
        let sut = DefaultLanguageRepository(store: store)

        // When
        let language = sut.fetchLanguage()

        // Then
        XCTAssertEqual(language, .ko)
    }
}

// MARK: - 저장 케이스

extension DefaultLanguageRepositoryTest {
    func test_새로운언어가주어진상태_언어저장시_스토어에올바른값을저장한다() {
        let store = MockKeyValueStoreService()
        let sut = DefaultLanguageRepository(store: store)

        // Given
        let language = Language.en

        // When
        sut.saveLanguage(language)

        // Then
        XCTAssertEqual(store.string(forKey: Policy.appSelectedLanguageKey), language.rawValue)
    }
}
