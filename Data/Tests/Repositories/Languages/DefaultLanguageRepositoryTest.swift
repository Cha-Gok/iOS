@testable import Data
import Domain
import XCTest

final class DefaultLanguageRepositoryTest: XCTestCase {}

// MARK: - 조회 성공 케이스

extension DefaultLanguageRepositoryTest {
    func test_기존언어데이터가있는상태_언어조회시_저장된언어를반환한다() async throws {
        let store = MockKeyValueStoreService()
        // Given: 저장된 언어 ko
        store.set("ko", forKey: Policy.appSelectedLanguageKey)
        let sut = DefaultLanguageRepository(store: store)

        // When
        let language = try await sut.fetchLanguage()

        // Then
        XCTAssertEqual(language, .ko)
    }

    func test_저장된언어데이터가없는상태_언어조회시_기본값인한국어를반환한다() async throws {
        let store = MockKeyValueStoreService()
        // Given: appSelectedLanguageKey 미설정 → string(forKey:) == nil
        let sut = DefaultLanguageRepository(store: store)

        // When
        let language = try await sut.fetchLanguage()

        // Then
        XCTAssertEqual(language, .ko)
    }
}

// MARK: - 저장 성공 케이스

extension DefaultLanguageRepositoryTest {
    func test_새로운언어가주어진상태_언어저장시_스토어에올바른값을저장한다() async throws {
        let store = MockKeyValueStoreService()
        let sut = DefaultLanguageRepository(store: store)

        // Given
        let language = Language.en

        // When
        try await sut.saveLanguage(language)

        // Then
        XCTAssertEqual(store.string(forKey: Policy.appSelectedLanguageKey), language.rawValue)
    }
}

// MARK: - 취소 케이스

extension DefaultLanguageRepositoryTest {
    func test_태스크가취소된상태_언어조회시_cancelled에러를발생시킨다() async throws {
        let store = MockKeyValueStoreService()
        let sut = DefaultLanguageRepository(store: store)

        // Given
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await sut.fetchLanguage()
        }

        // When & Then
        do {
            _ = try await task.value
            XCTFail("FetchLanguagesRepositoryError.cancelled 에러를 throw 해야 합니다.")
        } catch {
            guard case .cancelled = error as? FetchLanguagesRepositoryError else {
                return XCTFail("예상한 에러는 FetchLanguagesRepositoryError.cancelled 이지만, 실제 받은 에러는 \(error) 입니다.")
            }
        }
    }

    func test_태스크가취소된상태_언어저장시_cancelled에러를발생시킨다() async throws {
        let store = MockKeyValueStoreService()
        let sut = DefaultLanguageRepository(store: store)

        // Given
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            try await sut.saveLanguage(.ko)
        }

        // When & Then
        do {
            _ = try await task.value
            XCTFail("SetLanguagesRepositoryError.cancelled 에러를 throw 해야 합니다.")
        } catch {
            guard case .cancelled = error as? SetLanguagesRepositoryError else {
                return XCTFail("예상한 에러는 SetLanguagesRepositoryError.cancelled 이지만, 실제 받은 에러는 \(error) 입니다.")
            }
        }
    }
}
