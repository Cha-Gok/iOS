@testable import Data
import Domain
import XCTest

actor MockFolderLocalDataBase: LocalDataBase {
    typealias Domain = Folder

    private var createResult: Result<Domain, Error>?
    private var fetchOneResult: Result<Domain, Error>?
    private var fetchAllResult: Result<[Domain], Error>?
    private var updateResult: Result<Domain, Error>?
    private var deleteResult: Result<Domain, Error>?

    private var actualCreateCallCount = 0
    private var actualFetchOneCallCount = 0
    private var actualFetchAllCallCount = 0
    private var actualUpdateCallCount = 0
    private var actualDeleteCallCount = 0

    private var expectedCreateCallCount: Int?
    private var expectedFetchOneCallCount: Int?
    private var expectedFetchAllCallCount: Int?
    private var expectedUpdateCallCount: Int?
    private var expectedDeleteCallCount: Int?

    enum MockError: Error {
        case createFailed
        case fetchFailed
        case updateFailed
        case deleteFailed
    }

    init() {}

    func setCreateResult(_ result: Result<Domain, Error>) {
        createResult = result
    }

    func setFetchOneResult(_ result: Result<Domain, Error>) {
        fetchOneResult = result
    }

    func setFetchAllResult(_ result: Result<[Domain], Error>) {
        fetchAllResult = result
    }

    func setUpdateResult(_ result: Result<Domain, Error>) {
        updateResult = result
    }

    func setDeleteResult(_ result: Result<Domain, Error>) {
        deleteResult = result
    }

    func expectCreate(callCount: Int) {
        expectedCreateCallCount = callCount
    }

    func expectFetchOne(callCount: Int) {
        expectedFetchOneCallCount = callCount
    }

    func expectFetchAll(callCount: Int) {
        expectedFetchAllCallCount = callCount
    }

    func expectUpdate(callCount: Int) {
        expectedUpdateCallCount = callCount
    }

    func expectDelete(callCount: Int) {
        expectedDeleteCallCount = callCount
    }

    func verify(file: StaticString = #filePath, line: UInt = #line) {
        if let expected = expectedCreateCallCount {
            XCTAssertEqual(actualCreateCallCount, expected, "create 호출 횟수가 일치하지 않습니다.", file: file, line: line)
        }
        if let expected = expectedFetchOneCallCount {
            XCTAssertEqual(actualFetchOneCallCount, expected, "fetch(byId:) 호출 횟수가 일치하지 않습니다.", file: file, line: line)
        }
        if let expected = expectedFetchAllCallCount {
            XCTAssertEqual(actualFetchAllCallCount, expected, "fetchAll 호출 횟수가 일치하지 않습니다.", file: file, line: line)
        }
        if let expected = expectedUpdateCallCount {
            XCTAssertEqual(actualUpdateCallCount, expected, "update 호출 횟수가 일치하지 않습니다.", file: file, line: line)
        }
        if let expected = expectedDeleteCallCount {
            XCTAssertEqual(actualDeleteCallCount, expected, "delete 호출 횟수가 일치하지 않습니다.", file: file, line: line)
        }
    }

    func create(_ item: Domain) async throws -> Domain {
        actualCreateCallCount += 1
        switch createResult {
        case .success(let domain):
            return domain
        case .failure(let error):
            throw error
        case .none:
            XCTFail("MockFolderLocalDataBase.createResult 가 설정되지 않았습니다.")
            throw MockError.createFailed
        }
    }

    func fetch(byId id: Domain.ID) async throws -> Domain {
        actualFetchOneCallCount += 1
        switch fetchOneResult {
        case .success(let domain):
            return domain
        case .failure(let error):
            throw error
        case .none:
            XCTFail("MockFolderLocalDataBase.fetchOneResult 가 설정되지 않았습니다.")
            throw MockError.fetchFailed
        }
    }

    func fetchAll() async throws -> [Domain] {
        actualFetchAllCallCount += 1
        switch fetchAllResult {
        case .success(let domains):
            return domains
        case .failure(let error):
            throw error
        case .none:
            XCTFail("MockFolderLocalDataBase.fetchAllResult 가 설정되지 않았습니다.")
            throw MockError.fetchFailed
        }
    }

    func update(_ item: Domain) async throws -> Domain {
        actualUpdateCallCount += 1
        switch updateResult {
        case .success(let updatedDomain):
            return updatedDomain
        case .failure(let error):
            throw error
        case .none:
            XCTFail("MockFolderLocalDataBase.updateResult 가 설정되지 않았습니다.")
            throw MockError.updateFailed
        }
    }

    func delete(byId id: Domain.ID) async throws -> Domain {
        actualDeleteCallCount += 1
        switch deleteResult {
        case .success(let deletedDomain):
            return deletedDomain
        case .failure(let error):
            throw error
        case .none:
            XCTFail("MockFolderLocalDataBase.deleteResult 가 설정되지 않았습니다.")
            throw MockError.deleteFailed
        }
    }
}
