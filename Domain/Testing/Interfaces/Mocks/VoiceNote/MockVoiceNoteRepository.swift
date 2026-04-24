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
    private var observeResult: Result<AsyncStream<VoiceNote>, VoiceNoteRepositoryError>?
    private var observeFolderResult: Result<AsyncStream<[VoiceNote]>, VoiceNoteRepositoryError>?
    private var observeDefaultFolderResult: Result<AsyncStream<[VoiceNote]>, VoiceNoteRepositoryError>?
    private var observeRecentResult: Result<AsyncStream<[VoiceNote]>, VoiceNoteRepositoryError>?

    public init() {}

    // Call Counts
    private var createCallCount = 0
    private var updateCallCount = 0
    private var fetchCallCount = 0
    private var fetchAllFromDefaultFolderCallCount = 0
    private var fetchAllCallCount = 0
    private var fetchRecentCallCount = 0
    private var observeCallCount = 0
    private var observeFolderCallCount = 0
    private var observeDefaultFolderCallCount = 0
    private var observeRecentCallCount = 0

    // Actual Inputs
    private var actualVoiceRecord: VoiceRecord?
    private var actualUpdatedVoiceNote: VoiceNote?
    private var actualFetchID: UUID?
    private var actualFetchAllFolderID: UUID?
    private var actualFetchRecentLimit: Int?
    private var actualObserveFolderID: UUID?
    private var actualObserveRecentLimit: Int?

    // Expected Values
    private var expectedCreateCallCount: Int?
    private var expectedUpdateCallCount: Int?
    private var expectedFetchByIdCallCount: Int?
    private var expectedDefaultFetchCallCount: Int?
    private var expectedFetchAllCallCount: Int?
    private var expectedFetchAllFolderID: UUID?
    private var expectedFetchRecentCallCount: Int?
    private var expectedObserveCallCount: Int?
    private var expectedObserveFolderCallCount: Int?
    private var expectedObserveFolderID: UUID?
    private var expectedObserveDefaultFolderCallCount: Int?
    private var expectedObserveRecentCallCount: Int?
    private var expectedObserveRecentLimit: Int?

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

    public func setObserveResult(_ result: Result<AsyncStream<VoiceNote>, VoiceNoteRepositoryError>) {
        observeResult = result
    }

    public func setObserveFolderResult(_ result: Result<AsyncStream<[VoiceNote]>, VoiceNoteRepositoryError>) {
        observeFolderResult = result
    }

    public func setObserveDefaultFolderResult(_ result: Result<AsyncStream<[VoiceNote]>, VoiceNoteRepositoryError>) {
        observeDefaultFolderResult = result
    }

    public func setObserveRecentResult(_ result: Result<AsyncStream<[VoiceNote]>, VoiceNoteRepositoryError>) {
        observeRecentResult = result
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

    public func expectObserve(callCount: Int) {
        expectedObserveCallCount = callCount
    }

    public func expectObserveFolder(callCount: Int, folderID: UUID? = nil) {
        expectedObserveFolderCallCount = callCount
        expectedObserveFolderID = folderID
    }

    public func expectObserveDefaultFolder(callCount: Int) {
        expectedObserveDefaultFolderCallCount = callCount
    }

    public func expectObserveRecent(callCount: Int, limit: Int? = nil) {
        expectedObserveRecentCallCount = callCount
        expectedObserveRecentLimit = limit
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
        if let exp = expectedObserveCallCount { XCTAssertEqual(
            observeCallCount,
            exp,
            "observe 호출 횟수 불일치",
            file: file,
            line: line
        ) }
        if let exp = expectedObserveFolderCallCount { XCTAssertEqual(
            observeFolderCallCount,
            exp,
            "observe(folderID:) 호출 횟수 불일치",
            file: file,
            line: line
        ) }
        if let expID = expectedObserveFolderID { XCTAssertEqual(
            actualObserveFolderID,
            expID,
            "observe folderID 불일치",
            file: file,
            line: line
        ) }
        if let exp = expectedObserveDefaultFolderCallCount { XCTAssertEqual(
            observeDefaultFolderCallCount,
            exp,
            "observeAllFromDefaultFolder 호출 횟수 불일치",
            file: file,
            line: line
        ) }
        if let exp = expectedObserveRecentCallCount { XCTAssertEqual(
            observeRecentCallCount,
            exp,
            "observeRecent 호출 횟수 불일치",
            file: file,
            line: line
        ) }
        if let expLimit = expectedObserveRecentLimit { XCTAssertEqual(
            actualObserveRecentLimit,
            expLimit,
            "observeRecent limit 불일치",
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

    public func observe(id: UUID) throws(VoiceNoteRepositoryError) -> AsyncStream<VoiceNote> {
        observeCallCount += 1
        switch observeResult {
        case .success(let stream): return stream
        case .failure(let err): throw err
        case .none: XCTFail("observeResult 미설정")
            throw .unknown(NSError(domain: "Mock", code: -1))
        }
    }

    public func observe(folderID: UUID) throws(VoiceNoteRepositoryError) -> AsyncStream<[VoiceNote]> {
        observeFolderCallCount += 1
        actualObserveFolderID = folderID
        switch observeFolderResult {
        case .success(let stream): return stream
        case .failure(let err): throw err
        case .none: XCTFail("observeFolderResult 미설정")
            throw .unknown(NSError(domain: "Mock", code: -1))
        }
    }

    public func observeAllFromDefaultFolder() throws(VoiceNoteRepositoryError) -> AsyncStream<[VoiceNote]> {
        observeDefaultFolderCallCount += 1
        switch observeDefaultFolderResult {
        case .success(let stream): return stream
        case .failure(let err): throw err
        case .none: XCTFail("observeDefaultFolderResult 미설정")
            throw .unknown(NSError(domain: "Mock", code: -1))
        }
    }

    public func observeRecent(limit: Int) throws(VoiceNoteRepositoryError) -> AsyncStream<[VoiceNote]> {
        observeRecentCallCount += 1
        actualObserveRecentLimit = limit
        switch observeRecentResult {
        case .success(let stream): return stream
        case .failure(let err): throw err
        case .none: XCTFail("observeRecentResult 미설정")
            throw .unknown(NSError(domain: "Mock", code: -1))
        }
    }
}
