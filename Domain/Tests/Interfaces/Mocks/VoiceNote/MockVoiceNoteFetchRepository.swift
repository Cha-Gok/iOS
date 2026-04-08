@testable import Domain
import Foundation
import XCTest

public actor MockVoiceNoteFetchRepository: VoiceNoteFetchRepository {
    private var fetchAllResult: Result<[VoiceNote], VoiceNoteFetchRepositoryError>?
    private var fetchByIdResult: Result<VoiceNote, VoiceNoteFetchRepositoryError>?

    public init() {}

    private var fetchAllFromDefaultFolderCallCount = 0
    private var expectedDefaultFetchCallCount: Int?

    private var fetchAllCallCount = 0
    private var actualFetchAllFolderID: UUID?
    private var fetchByIdCallCount = 0
    private var actualFetchByIdID: UUID?

    private var expectedFetchAllCallCount: Int?
    private var expectedFetchAllFolderID: UUID?
    private var expectedFetchByIdCallCount: Int?
    private var expectedFetchByIdID: UUID?

    public func setFetchAllResult(_ result: Result<[VoiceNote], VoiceNoteFetchRepositoryError>) {
        fetchAllResult = result
    }

    public func setFetchByIdResult(_ result: Result<VoiceNote, VoiceNoteFetchRepositoryError>) {
        fetchByIdResult = result
    }

    public func expectFetchAllFromDefaultFolder(callCount: Int) {
        expectedDefaultFetchCallCount = callCount
    }

    public func expectFetchAll(callCount: Int, folderID: UUID? = nil) {
        expectedFetchAllCallCount = callCount
        expectedFetchAllFolderID = folderID
    }

    public func expectFetchById(callCount: Int, id: UUID? = nil) {
        expectedFetchByIdCallCount = callCount
        expectedFetchByIdID = id
    }

    public func verify(file: StaticString = #filePath, line: UInt = #line) {
        if let expected = expectedDefaultFetchCallCount {
            XCTAssertEqual(
                fetchAllFromDefaultFolderCallCount,
                expected,
                "기본 폴더 전체 조회 호출 횟수가 일치하지 않습니다.",
                file: file,
                line: line
            )
        }
        if let expected = expectedFetchAllCallCount {
            XCTAssertEqual(
                fetchAllCallCount,
                expected,
                "전체 조회 호출 횟수가 일치하지 않습니다.",
                file: file,
                line: line
            )
        }
        if let expectedFolderID = expectedFetchAllFolderID {
            XCTAssertEqual(
                actualFetchAllFolderID,
                expectedFolderID,
                "전체 조회 폴더 ID가 일치하지 않습니다.",
                file: file,
                line: line
            )
        }
        if let expected = expectedFetchByIdCallCount {
            XCTAssertEqual(
                fetchByIdCallCount,
                expected,
                "ID별 조회 호출 횟수가 일치하지 않습니다.",
                file: file,
                line: line
            )
        }
        if let expectedID = expectedFetchByIdID {
            XCTAssertEqual(
                actualFetchByIdID,
                expectedID,
                "ID별 조회 ID가 일치하지 않습니다.",
                file: file,
                line: line
            )
        }
    }

    public func fetchAllFromDefaultFolder() async throws(VoiceNoteFetchRepositoryError) -> [VoiceNote] {
        fetchAllFromDefaultFolderCallCount += 1

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

    public func fetchAll(folderID: UUID) async throws(VoiceNoteFetchRepositoryError) -> [VoiceNote] {
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

    public func fetch(byId id: UUID) async throws(VoiceNoteFetchRepositoryError) -> VoiceNote {
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
