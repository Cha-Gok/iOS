@testable import Data
import Domain
import XCTest

final class MockLanguageService: LanguageService, @unchecked Sendable {
    private var fetchResult: Result<String, LanguageServiceError>?

    private var actualFetchCallCount = 0
    private var actualSaveCallCount = 0
    private var actualSavedLanguage: String?

    private var expectedFetchCallCount: Int?
    private var expectedSaveCallCount: Int?
    private var expectedSavedLanguage: String?

    func setFetchResult(_ result: Result<String, LanguageServiceError>) {
        fetchResult = result
    }

    func expectFetch(callCount: Int) {
        expectedFetchCallCount = callCount
    }

    func expectSave(language: String? = nil, callCount: Int) {
        expectedSavedLanguage = language
        expectedSaveCallCount = callCount
    }

    func verify(file: StaticString = #filePath, line: UInt = #line) {
        if let expected = expectedFetchCallCount {
            XCTAssertEqual(
                actualFetchCallCount,
                expected,
                "fetchLanguage 호출 횟수가 일치하지 않습니다.",
                file: file,
                line: line
            )
        }
        if let expected = expectedSaveCallCount {
            XCTAssertEqual(
                actualSaveCallCount,
                expected,
                "saveLanguage 호출 횟수가 일치하지 않습니다.",
                file: file,
                line: line
            )
        }
        if let expected = expectedSavedLanguage {
            XCTAssertEqual(
                actualSavedLanguage,
                expected,
                "saveLanguage에 전달된 언어가 일치하지 않습니다.",
                file: file,
                line: line
            )
        }
    }

    func fetchLanguage() throws(LanguageServiceError) -> String {
        actualFetchCallCount += 1
        guard let result = fetchResult else {
            XCTFail("fetchResult이 설정되지 않았습니다. setFetchResult()를 먼저 호출하세요.")
            throw .notFound
        }

        switch result {
        case .success(let language):
            return language
        case .failure(let error):
            throw error
        }
    }

    func saveLanguage(_ language: String) {
        actualSaveCallCount += 1
        actualSavedLanguage = language
    }
}
