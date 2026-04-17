@testable import Domain
import Foundation
import XCTest

@MainActor
public final class MockWasteBasketRepository: WasteBasketRepository, @unchecked Sendable {
    // Results
    private var deleteResult: Result<Void, DeleteWasteBasketRepositoryError>?
    private var moveResult: Result<Void, MoveWasteBasketRepositoryError>?
    private var fetchAllResult: Result<[WasteBasketItem], FetchWasteBasketRepositoryError>?
    private var restoreResult: Result<Void, RestoreWasteBasketRepositoryError>?

    // 호출 검증 Count
    private var fetchAllCallCount = 0
    private var moveToWasteBasketCallCount = 0
    private var moveAllToWasteBasketCallCount = 0
    private var deleteCallCount = 0
    private var deleteAllCallCount = 0
    private var allClearCallCount = 0
    private var restoreCallCount = 0
    private var restoreAllCallCount = 0

    // Expected Call Counts
    private var expectedFetchAllCallCount: Int?
    private var expectedMoveToWasteBasketCallCount: Int?
    private var expectedMoveAllToWasteBasketCallCount: Int?
    private var expectedDeleteCallCount: Int?
    private var expectedDeleteAllCallCount: Int?
    private var expectedAllClearCallCount: Int?
    private var expectedRestoreCallCount: Int?
    private var expectedRestoreAllCallCount: Int?

    // Expected Arguments
    private var expectedLastMovedItem: WasteBasketItem?
    private var expectedLastMovedItems: [WasteBasketItem]?
    private var expectedLastDeletedItem: WasteBasketItem?
    private var expectedLastDeletedItems: [WasteBasketItem]?
    private var expectedLastRestoredItem: WasteBasketItem?
    private var expectedLastRestoredItems: [WasteBasketItem]?

    // 받은 인자 기록 (Verification용)
    private var lastMovedItem: WasteBasketItem?
    private var lastMovedItems: [WasteBasketItem]?
    private var lastDeletedItem: WasteBasketItem?
    private var lastDeletedItems: [WasteBasketItem]?
    private var lastRestoredItem: WasteBasketItem?
    private var lastRestoredItems: [WasteBasketItem]?

    // MARK: - Setup

    public init() {}

    public func setFetchAllResult(_ result: Result<[WasteBasketItem], FetchWasteBasketRepositoryError>) {
        fetchAllResult = result
    }

    public func setMoveResult(_ result: Result<Void, MoveWasteBasketRepositoryError>) {
        moveResult = result
    }

    public func setDeleteResult(_ result: Result<Void, DeleteWasteBasketRepositoryError>) {
        deleteResult = result
    }

    public func setRestoreResult(_ result: Result<Void, RestoreWasteBasketRepositoryError>) {
        restoreResult = result
    }

    // MARK: - Expectations

    public func expectFetchAll(callCount: Int) {
        expectedFetchAllCallCount = callCount
    }

    public func expectMoveToWasteBasket(item: WasteBasketItem? = nil, callCount: Int) {
        expectedMoveToWasteBasketCallCount = callCount
        expectedLastMovedItem = item
    }

    public func expectMoveAllToWasteBasket(items: [WasteBasketItem]? = nil, callCount: Int) {
        expectedMoveAllToWasteBasketCallCount = callCount
        expectedLastMovedItems = items
    }

    public func expectDelete(item: WasteBasketItem? = nil, callCount: Int) {
        expectedDeleteCallCount = callCount
        expectedLastDeletedItem = item
    }

    public func expectDeleteAll(items: [WasteBasketItem]? = nil, callCount: Int) {
        expectedDeleteAllCallCount = callCount
        expectedLastDeletedItems = items
    }

    public func expectAllClear(callCount: Int) {
        expectedAllClearCallCount = callCount
    }

    public func expectRestore(item: WasteBasketItem? = nil, callCount: Int) {
        expectedRestoreCallCount = callCount
        expectedLastRestoredItem = item
    }

    public func expectRestoreAll(items: [WasteBasketItem]? = nil, callCount: Int) {
        expectedRestoreAllCallCount = callCount
        expectedLastRestoredItems = items
    }

    // MARK: - Verification

    public func verify(file: StaticString = #filePath, line: UInt = #line) {
        verifyFetch(file: file, line: line)
        verifyMove(file: file, line: line)
        verifyDelete(file: file, line: line)
        verifyRestore(file: file, line: line)
    }

    private func verifyFetch(file: StaticString, line: UInt) {
        if let expected = expectedFetchAllCallCount {
            XCTAssertEqual(fetchAllCallCount, expected, "전체 조회 호출 횟수가 일치하지 않습니다.", file: file, line: line)
        }
    }

    private func verifyMove(file: StaticString, line: UInt) {
        if let expected = expectedMoveToWasteBasketCallCount {
            XCTAssertEqual(
                moveToWasteBasketCallCount, expected, "휴지통으로 이동 호출 횟수가 일치하지 않습니다.", file: file, line: line
            )
        }
        if let expected = expectedMoveAllToWasteBasketCallCount {
            XCTAssertEqual(
                moveAllToWasteBasketCallCount, expected, "전체 휴지통으로 이동 호출 횟수가 일치하지 않습니다.", file: file, line: line
            )
        }
        if let expected = expectedLastMovedItem {
            XCTAssertEqual(lastMovedItem, expected, "마지막으로 이동된 항목이 일치하지 않습니다.", file: file, line: line)
        }
        if let expected = expectedLastMovedItems {
            XCTAssertEqual(lastMovedItems, expected, "마지막으로 이동된 항목 목록이 일치하지 않습니다.", file: file, line: line)
        }
    }

    private func verifyDelete(file: StaticString, line: UInt) {
        if let expected = expectedDeleteCallCount {
            XCTAssertEqual(deleteCallCount, expected, "삭제 호출 횟수가 일치하지 않습니다.", file: file, line: line)
        }
        if let expected = expectedDeleteAllCallCount {
            XCTAssertEqual(deleteAllCallCount, expected, "전체 삭제 호출 횟수가 일치하지 않습니다.", file: file, line: line)
        }
        if let expected = expectedAllClearCallCount {
            XCTAssertEqual(allClearCallCount, expected, "비우기 호출 횟수가 일치하지 않습니다.", file: file, line: line)
        }
        if let expected = expectedLastDeletedItem {
            XCTAssertEqual(lastDeletedItem, expected, "마지막으로 삭제된 항목이 일치하지 않습니다.", file: file, line: line)
        }
        if let expected = expectedLastDeletedItems {
            XCTAssertEqual(lastDeletedItems, expected, "마지막으로 삭제된 항목 목록이 일치하지 않습니다.", file: file, line: line)
        }
    }

    private func verifyRestore(file: StaticString, line: UInt) {
        if let expected = expectedRestoreCallCount {
            XCTAssertEqual(restoreCallCount, expected, "복원 호출 횟수가 일치하지 않습니다.", file: file, line: line)
        }
        if let expected = expectedRestoreAllCallCount {
            XCTAssertEqual(restoreAllCallCount, expected, "전체 복원 호출 횟수가 일치하지 않습니다.", file: file, line: line)
        }
        if let expected = expectedLastRestoredItem {
            XCTAssertEqual(lastRestoredItem, expected, "마지막으로 복원된 항목이 일치하지 않습니다.", file: file, line: line)
        }
        if let expected = expectedLastRestoredItems {
            XCTAssertEqual(
                lastRestoredItems, expected, "마지막으로 복원된 항목 목록이 일치하지 않습니다.", file: file, line: line
            )
        }
    }

    // MARK: - WasteBasketRepository (Fetch, Move, Delete)

    public func fetchAll() throws(FetchWasteBasketRepositoryError) -> [WasteBasketItem] {
        fetchAllCallCount += 1

        switch fetchAllResult {
        case .success(let items):
            return items
        case .failure(let error):
            throw error
        case .none:
            XCTFail("MockWasteBasketRepository.fetchAllResult 가 설정되지 않았습니다.")
            let error = NSError(domain: "MockWasteBasketRepository.fetchAllResult", code: 0)
            throw .unknown(error)
        }
    }

    public func moveToWasteBasket(item: WasteBasketItem) throws(MoveWasteBasketRepositoryError) {
        moveToWasteBasketCallCount += 1
        lastMovedItem = item

        switch moveResult {
        case .success:
            return
        case .failure(let error):
            throw error
        case .none:
            XCTFail("MockWasteBasketRepository.moveResult 가 설정되지 않았습니다.")
            let error = NSError(domain: "MockWasteBasketRepository.moveResult", code: 0)
            throw .unknown(error)
        }
    }

    public func moveAllToWasteBasket(items: [WasteBasketItem]) throws(MoveWasteBasketRepositoryError) {
        moveAllToWasteBasketCallCount += 1
        lastMovedItems = items

        switch moveResult {
        case .success:
            return
        case .failure(let error):
            throw error
        case .none:
            XCTFail("MockWasteBasketRepository.moveResult 가 설정되지 않았습니다.")
            let error = NSError(domain: "MockWasteBasketRepository.moveResult", code: 0)
            throw .unknown(error)
        }
    }

    public func delete(item: WasteBasketItem) throws(DeleteWasteBasketRepositoryError) {
        deleteCallCount += 1
        lastDeletedItem = item

        switch deleteResult {
        case .success:
            return
        case .failure(let error):
            throw error
        case .none:
            XCTFail("MockWasteBasketRepository.deleteResult 가 설정되지 않았습니다.")
            let error = NSError(domain: "MockWasteBasketRepository.deleteResult", code: 0)
            throw .unknown(error)
        }
    }

    public func deleteAll(items: [WasteBasketItem]) throws(DeleteWasteBasketRepositoryError) {
        deleteAllCallCount += 1
        lastDeletedItems = items

        switch deleteResult {
        case .success:
            return
        case .failure(let error):
            throw error
        case .none:
            XCTFail("MockWasteBasketRepository.deleteResult 가 설정되지 않았습니다.")
            let error = NSError(domain: "MockWasteBasketRepository.deleteResult", code: 0)
            throw .unknown(error)
        }
    }

    public func allClear() throws(DeleteWasteBasketRepositoryError) {
        allClearCallCount += 1

        switch deleteResult {
        case .success:
            return
        case .failure(let error):
            throw error
        case .none:
            XCTFail("MockWasteBasketRepository.deleteResult 가 설정되지 않았습니다.")
            let error = NSError(domain: "MockWasteBasketRepository.deleteResult", code: 0)
            throw .unknown(error)
        }
    }

    public func restore(item: WasteBasketItem) throws(RestoreWasteBasketRepositoryError) {
        restoreCallCount += 1
        lastRestoredItem = item

        switch restoreResult {
        case .success:
            return
        case .failure(let error):
            throw error
        case .none:
            XCTFail("MockWasteBasketRepository.restoreResult 가 설정되지 않았습니다.")
            let error = NSError(domain: "MockWasteBasketRepository.restoreResult", code: 0)
            throw .unknown(error)
        }
    }

    public func restoreAll(items: [WasteBasketItem]) throws(RestoreWasteBasketRepositoryError) {
        restoreAllCallCount += 1
        lastRestoredItems = items

        switch restoreResult {
        case .success:
            return
        case .failure(let error):
            throw error
        case .none:
            XCTFail("MockWasteBasketRepository.restoreResult 가 설정되지 않았습니다.")
            let error = NSError(domain: "MockWasteBasketRepository.restoreResult", code: 0)
            throw .unknown(error)
        }
    }
}
