@testable import Domain
import Foundation
import XCTest

actor MockLanguageRepository: LanguageRepository {
    private var fetchResult: Result<Language, FetchLanguagesRepositoryError>?
    private var saveResult: Result<Void, SetLanguagesRepositoryError>?

    private var fetchCallCount = 0
    private var saveCallCount = 0

    private var expectedFetchCallCount: Int?
    private var expectedSaveCallCount: Int?
    private var expectedLastSavedLanguage: Language?

    private var lastSavedLanguage: Language?

    func setFetchResult(_ result: Result<Language, FetchLanguagesRepositoryError>) {
        fetchResult = result
    }

    func setSaveResult(_ result: Result<Void, SetLanguagesRepositoryError>) {
        saveResult = result
    }

    func expectFetch(callCount: Int) {
        expectedFetchCallCount = callCount
    }

    func expectSave(language: Language? = nil, callCount: Int) {
        expectedSaveCallCount = callCount
        expectedLastSavedLanguage = language
    }

    func verify(file: StaticString = #filePath, line: UInt = #line) {
        if let expected = expectedFetchCallCount {
            XCTAssertEqual(
                fetchCallCount,
                expected,
                "조회 호출 횟수가 일치하지 않습니다.",
                file: file,
                line: line
            )
        }
        if let expected = expectedSaveCallCount {
            XCTAssertEqual(
                saveCallCount,
                expected,
                "저장 호출 횟수가 일치하지 않습니다.",
                file: file,
                line: line
            )
        }

        if let expected = expectedLastSavedLanguage {
            XCTAssertEqual(
                lastSavedLanguage,
                expected,
                "마지막으로 저장된 언어가 일치하지 않습니다.",
                file: file,
                line: line
            )
        }
    }

    func fetchLanguage() async throws(FetchLanguagesRepositoryError) -> Language {
        fetchCallCount += 1

        switch fetchResult {
        case .success(let lang):
            return lang
        case .failure(let error):
            throw error
        case .none:
            XCTFail("MockLanguageRepository.fetchResult 가 설정되지 않았습니다.")
            let error = NSError(domain: "MockLanguageRepository.fetchResult", code: 0)
            throw .unknown(error)
        }
    }

    func saveLanguage(_ language: Language) async throws(SetLanguagesRepositoryError) {
        saveCallCount += 1
        lastSavedLanguage = language

        switch saveResult {
        case .success:
            return
        case .failure(let error):
            throw error
        case .none:
            XCTFail("MockLanguageRepository.saveResult 가 설정되지 않았습니다.")
            let error = NSError(domain: "MockLanguageRepository.saveResult", code: 0)
            throw .unknown(error)
        }
    }
}
