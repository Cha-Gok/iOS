@testable import Domain
import Foundation
import XCTest

@MainActor
public final class MockVoiceNoteRepository: VoiceNoteRepository {
    private var createResult: Result<VoiceNote, VoiceNoteRepositoryError>?
    private var updateResult: Result<VoiceNote, VoiceNoteRepositoryError>?
    private var fetchResult: Result<VoiceNote, VoiceNoteRepositoryError>?
    private var fetchAllResult: Result<[VoiceNote], VoiceNoteRepositoryError>?
    private var fetchRecentResult: Result<[VoiceNote], VoiceNoteRepositoryError>?

    public init() {}

    // Call Counts
    private var createCallCount = 0
    private var updateCallCount = 0
    private var fetchCallCount = 0
    private var fetchAllFromDefaultFolderCallCount = 0
    private var fetchAllCallCount = 0
    private var fetchRecentCallCount = 0

    // Actual Inputs
    private var actualVoiceRecord: VoiceRecord?
    private var actualUpdatedVoiceNote: VoiceNote?
    private var actualFetchID: UUID?
    private var actualFetchAllFolderID: UUID?
    private var actualFetchRecentLimit: Int?

    // Expected Values
    private var expectedCreateCallCount: Int?
    private var expectedUpdateCallCount: Int?
    private var expectedFetchByIdCallCount: Int?
    private var expectedDefaultFetchCallCount: Int?
    private var expectedFetchAllCallCount: Int?
    private var expectedFetchAllFolderID: UUID?
    private var expectedFetchRecentCallCount: Int?

    /// Set Results
    public func setCreateResult(_ result: Result<VoiceNote, VoiceNoteRepositoryError>) {
        createResult = result
    }

    public func setUpdateResult(_ result: Result<VoiceNote, VoiceNoteRepositoryError>) {
        updateResult = result
    }

    public func setFetchResult(_ result: Result<VoiceNote, VoiceNoteRepositoryError>) {
        fetchResult = result
    }

    public func setFetchAllResult(_ result: Result<[VoiceNote], VoiceNoteRepositoryError>) {
        fetchAllResult = result
    }

    public func setFetchRecentResult(_ result: Result<[VoiceNote], VoiceNoteRepositoryError>) {
        fetchRecentResult = result
    }

    /// Expect Methods
    public func expectCreate(callCount: Int) {
        expectedCreateCallCount = callCount
    }

    public func expectUpdate(callCount: Int) {
        expectedUpdateCallCount = callCount
    }

    public func expectFetchById(callCount: Int) {
        expectedFetchByIdCallCount = callCount
    }

    public func expectFetchAllFromDefaultFolder(callCount: Int) {
        expectedDefaultFetchCallCount = callCount
    }

    public func expectFetchAll(callCount: Int, folderID: UUID? = nil) {
        expectedFetchAllCallCount = callCount
        expectedFetchAllFolderID = folderID
    }

    public func expectFetchRecent(callCount: Int) {
        expectedFetchRecentCallCount = callCount
    }

    public func verify(file: StaticString = #filePath, line: UInt = #line) {
        if let exp = expectedCreateCallCount { XCTAssertEqual(
            createCallCount,
            exp,
            "create 호출 횟수 불일치",
            file: file,
            line: line
        ) }
        if let exp = expectedUpdateCallCount { XCTAssertEqual(
            updateCallCount,
            exp,
            "update 호출 횟수 불일치",
            file: file,
            line: line
        ) }
        if let exp = expectedFetchByIdCallCount { XCTAssertEqual(
            fetchCallCount,
            exp,
            "fetch(byId:) 호출 횟수 불일치",
            file: file,
            line: line
        ) }
        if let exp = expectedDefaultFetchCallCount { XCTAssertEqual(
            fetchAllFromDefaultFolderCallCount,
            exp,
            "fetchAllFromDefaultFolder 호출 횟수 불일치",
            file: file,
            line: line
        ) }
        if let exp = expectedFetchAllCallCount { XCTAssertEqual(
            fetchAllCallCount,
            exp,
            "fetchAll(folderID:) 호출 횟수 불일치",
            file: file,
            line: line
        ) }
        if let expID = expectedFetchAllFolderID { XCTAssertEqual(
            actualFetchAllFolderID,
            expID,
            "fetchAll folderID 불일치",
            file: file,
            line: line
        ) }
        if let exp = expectedFetchRecentCallCount { XCTAssertEqual(
            fetchRecentCallCount,
            exp,
            "fetchRecent 호출 횟수 불일치",
            file: file,
            line: line
        ) }
    }

    // Repository Implementations

    public func create(_ voiceRecord: VoiceRecord) throws(VoiceNoteRepositoryError) -> VoiceNote {
        createCallCount += 1
        actualVoiceRecord = voiceRecord
        switch createResult {
        case .success(let val): return val
        case .failure(let err): throw err
        case .none: XCTFail("createResult 미설정")
            throw .unknown(NSError(domain: "Mock", code: -1))
        }
    }

    public func update(_ voiceNote: VoiceNote) throws(VoiceNoteRepositoryError) -> VoiceNote {
        updateCallCount += 1
        actualUpdatedVoiceNote = voiceNote
        switch updateResult {
        case .success(let val): return val
        case .failure(let err): throw err
        case .none: XCTFail("updateResult 미설정")
            throw .unknown(NSError(domain: "Mock", code: -1))
        }
    }

    public func fetchAllFromDefaultFolder() throws(VoiceNoteRepositoryError) -> [VoiceNote] {
        fetchAllFromDefaultFolderCallCount += 1
        switch fetchAllResult {
        case .success(let val): return val
        case .failure(let err): throw err
        case .none: XCTFail("fetchAllResult 미설정")
            throw .unknown(NSError(domain: "Mock", code: -1))
        }
    }

    public func fetchAll(folderID: UUID) throws(VoiceNoteRepositoryError) -> [VoiceNote] {
        fetchAllCallCount += 1
        actualFetchAllFolderID = folderID
        switch fetchAllResult {
        case .success(let val): return val
        case .failure(let err): throw err
        case .none: XCTFail("fetchAllResult 미설정")
            throw .unknown(NSError(domain: "Mock", code: -1))
        }
    }

    public func fetch(byId id: UUID) throws(VoiceNoteRepositoryError) -> VoiceNote {
        fetchCallCount += 1
        actualFetchID = id
        switch fetchResult {
        case .success(let val): return val
        case .failure(let err): throw err
        case .none: XCTFail("fetchResult 미설정")
            throw .unknown(NSError(domain: "Mock", code: -1))
        }
    }

    public func fetchRecent(limit: Int) throws(VoiceNoteRepositoryError) -> [VoiceNote] {
        fetchRecentCallCount += 1
        actualFetchRecentLimit = limit
        switch fetchRecentResult {
        case .success(let val): return val
        case .failure(let err): throw err
        case .none: XCTFail("fetchRecentResult 미설정")
            throw .unknown(NSError(domain: "Mock", code: -1))
        }
    }
}
