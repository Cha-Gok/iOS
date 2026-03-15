import Foundation
import XCTest

@testable import Domain

actor MockLanguageRepository: LanguageRepository {

    private var fetchResult: Result<Language, FetchLanguagesRepositoryError>?
    private var selectResult: Result<Void, SetLanguagesRepositoryError>?

    private(set) var fetchCallCount = 0
    private(set) var selectCallCount = 0

    private var expectedFetchCallCount: Int?
    private var expectedSelectCallCount: Int?

    func setFetchResult(_ result: Result<Language, FetchLanguagesRepositoryError>) {
        self.fetchResult = result
    }

    func setSelectResult(_ result: Result<Void, SetLanguagesRepositoryError>) {
        self.selectResult = result
    }

    func expectFetch(callCount: Int) {
        expectedFetchCallCount = callCount
    }

    func expectSelect(callCount: Int) {
        expectedSelectCallCount = callCount
    }

    func verify(file: StaticString = #filePath, line: UInt = #line) {
        if let expected = expectedFetchCallCount {
            XCTAssertEqual(
                fetchCallCount,
                expected,
                "fetch call count mismatch",
                file: file,
                line: line
            )
        }
        if let expected = expectedSelectCallCount {
            XCTAssertEqual(
                selectCallCount,
                expected,
                "select call count mismatch",
                file: file,
                line: line
            )
        }
    }

    func fetchLanguage() async throws(FetchLanguagesRepositoryError) -> Language {
        fetchCallCount += 1

        guard let fetchResult = fetchResult else {
            fatalError("MockLanguageRepository.fetchResult not set")
        }

        switch fetchResult {
            case .success(let lang):
                return lang
            case .failure(let error):
                throw error
        }
    }

    func saveLanguage(_ language: Language) async throws(SetLanguagesRepositoryError) {
        selectCallCount += 1

        guard let selectResult = selectResult else {
            fatalError("MockLanguageRepository.selectResult not set")
        }

        switch selectResult {
            case .success:
                return
            case .failure(let error):
                throw error
        }
    }

}
