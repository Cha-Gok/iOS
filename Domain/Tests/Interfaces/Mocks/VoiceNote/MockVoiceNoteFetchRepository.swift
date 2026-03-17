@testable import Domain
import Foundation
import XCTest

actor MockVoiceNoteFetchRepository: VoiceNoteFetchRepository {
    private var fetchAllResult: Result<[VoiceNote], VoiceNoteFetchRepositoryError>?
    private var fetchByIdResult: Result<VoiceNote, VoiceNoteFetchRepositoryError>?

    private(set) var fetchAllCallCount = 0
    private(set) var actualFetchAllFolderID: UUID?
    private(set) var fetchByIdCallCount = 0
    private(set) var actualFetchByIdID: UUID?

    private var expectedFetchAllCallCount: Int?
    private var expectedFetchAllFolderID: UUID?
    private var expectedFetchByIdCallCount: Int?
    private var expectedFetchByIdID: UUID?

    func setFetchAllResult(_ result: Result<[VoiceNote], VoiceNoteFetchRepositoryError>) {
        fetchAllResult = result
    }

    func setFetchByIdResult(_ result: Result<VoiceNote, VoiceNoteFetchRepositoryError>) {
        fetchByIdResult = result
    }

    func expectFetchAll(callCount: Int, folderID: UUID? = nil) {
        expectedFetchAllCallCount = callCount
        expectedFetchAllFolderID = folderID
    }

    func expectFetchById(callCount: Int, id: UUID? = nil) {
        expectedFetchByIdCallCount = callCount
        expectedFetchByIdID = id
    }

    func verify(file: StaticString = #filePath, line: UInt = #line) {
        if let expected = expectedFetchAllCallCount {
            XCTAssertEqual(
                fetchAllCallCount,
                expected,
                "fetchAll call count mismatch",
                file: file,
                line: line
            )
        }
        if let expectedFolderID = expectedFetchAllFolderID {
            XCTAssertEqual(
                actualFetchAllFolderID,
                expectedFolderID,
                "fetchAll folderID mismatch",
                file: file,
                line: line
            )
        }
        if let expected = expectedFetchByIdCallCount {
            XCTAssertEqual(
                fetchByIdCallCount,
                expected,
                "fetch(byId:) call count mismatch",
                file: file,
                line: line
            )
        }
        if let expectedID = expectedFetchByIdID {
            XCTAssertEqual(
                actualFetchByIdID,
                expectedID,
                "fetch(byId:) id mismatch",
                file: file,
                line: line
            )
        }
    }

    func fetchAll(folderID: UUID) async throws(VoiceNoteFetchRepositoryError) -> [VoiceNote] {
        fetchAllCallCount += 1
        actualFetchAllFolderID = folderID

        switch fetchAllResult {
        case .success(let success):
            return success
        case .failure(let failure):
            throw failure
        case .none:
            XCTFail("MockVoiceNoteFetchRepository.fetchAllResult 가 설정되지 않았습니다.")
            throw .unknown(NSError(domain: "MockVoiceNoteFetchRepository.fetchAllResult", code: -1))
        }
    }

    func fetch(byId id: UUID) async throws(VoiceNoteFetchRepositoryError) -> VoiceNote {
        fetchByIdCallCount += 1
        actualFetchByIdID = id

        switch fetchByIdResult {
        case .success(let success):
            return success
        case .failure(let failure):
            throw failure
        case .none:
            XCTFail("MockVoiceNoteFetchRepository.fetchByIdResult 가 설정되지 않았습니다.")
            throw .unknown(
                NSError(domain: "MockVoiceNoteFetchRepository.fetchByIdResult", code: -1)
            )
        }
    }
}
