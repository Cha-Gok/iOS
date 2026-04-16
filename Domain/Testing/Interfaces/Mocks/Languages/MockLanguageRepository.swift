@testable import Domain
import Foundation
import XCTest

public actor MockLanguageRepository: LanguageRepository {
    public init() {}

    nonisolated(unsafe) private var fetchResult: Language?
    nonisolated(unsafe) private var fetchCallCount = 0
    nonisolated(unsafe) private var saveCallCount = 0
    nonisolated(unsafe) private var lastSavedLanguage: Language?

    private var expectedFetchCallCount: Int?
    private var expectedSaveCallCount: Int?
    private var expectedLastSavedLanguage: Language?

    public func setFetchResult(_ language: Language) {
        fetchResult = language
    }

    public func expectFetch(callCount: Int) {
        expectedFetchCallCount = callCount
    }

    public func expectSave(language: Language? = nil, callCount: Int) {
        expectedSaveCallCount = callCount
        expectedLastSavedLanguage = language
    }

    public func verify(file: StaticString = #filePath, line: UInt = #line) {
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

    public nonisolated func fetchLanguage() -> Language {
        fetchCallCount += 1
        return fetchResult ?? .ko
    }

    public nonisolated func saveLanguage(_ language: Language) {
        saveCallCount += 1
        lastSavedLanguage = language
    }
}
