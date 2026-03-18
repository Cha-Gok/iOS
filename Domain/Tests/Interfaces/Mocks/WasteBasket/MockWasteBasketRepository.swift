@testable import Domain
import Foundation
import XCTest

actor MockWasteBasketRepository: WasteBasketRepository {
    // Results
    private var deleteResult: Result<Void, DeleteWasteBasketRepositoryError>?
    private var moveResult: Result<Void, MoveWasteBasketRepositoryError>?
    private var fetchAllResult: Result<[WasteBasketItem], FetchWasteBasketRepositoryError>?

    // 호출 검증 Count
    private var fetchAllCallCount = 0
    private var moveToWasteBasketCallCount = 0
    private var moveAllToWasteBasketCallCount = 0
    private var deleteCallCount = 0
    private var deleteAllCallCount = 0
    private var allClearCallCount = 0

    // Expected Call Counts
    private var expectedFetchAllCallCount: Int?
    private var expectedMoveToWasteBasketCallCount: Int?
    private var expectedMoveAllToWasteBasketCallCount: Int?
    private var expectedDeleteCallCount: Int?
    private var expectedDeleteAllCallCount: Int?
    private var expectedAllClearCallCount: Int?

    // Expected Arguments
    private var expectedLastMovedItem: WasteBasketItem?
    private var expectedLastMovedItems: [WasteBasketItem]?
    private var expectedLastDeletedItem: WasteBasketItem?
    private var expectedLastDeletedItems: [WasteBasketItem]?

    // 받은 인자 기록 (Verification용)
    private var lastMovedItem: WasteBasketItem?
    private var lastMovedItems: [WasteBasketItem]?
    private var lastDeletedItem: WasteBasketItem?
    private var lastDeletedItems: [WasteBasketItem]?

    // MARK: - Setup

    func setFetchAllResult(_ result: Result<[WasteBasketItem], FetchWasteBasketRepositoryError>) {
        fetchAllResult = result
    }

    func setMoveResult(_ result: Result<Void, MoveWasteBasketRepositoryError>) {
        moveResult = result
    }

    func setDeleteResult(_ result: Result<Void, DeleteWasteBasketRepositoryError>) {
        deleteResult = result
    }

    // MARK: - Expectations

    func expectFetchAll(callCount: Int) {
        expectedFetchAllCallCount = callCount
    }

    func expectMoveToWasteBasket(item: WasteBasketItem? = nil, callCount: Int) {
        expectedMoveToWasteBasketCallCount = callCount
        expectedLastMovedItem = item
    }

    func expectMoveAllToWasteBasket(items: [WasteBasketItem]? = nil, callCount: Int) {
        expectedMoveAllToWasteBasketCallCount = callCount
        expectedLastMovedItems = items
    }

    func expectDelete(item: WasteBasketItem? = nil, callCount: Int) {
        expectedDeleteCallCount = callCount
        expectedLastDeletedItem = item
    }

    func expectDeleteAll(items: [WasteBasketItem]? = nil, callCount: Int) {
        expectedDeleteAllCallCount = callCount
        expectedLastDeletedItems = items
    }

    func expectAllClear(callCount: Int) {
        expectedAllClearCallCount = callCount
    }

    // MARK: - Verification

    func verify(file: StaticString = #filePath, line: UInt = #line) {
        if let expected = expectedFetchAllCallCount {
            XCTAssertEqual(fetchAllCallCount, expected, "전체 조회 호출 횟수가 일치하지 않습니다.", file: file, line: line)
        }
        if let expected = expectedMoveToWasteBasketCallCount {
            XCTAssertEqual(
                moveToWasteBasketCallCount,
                expected,
                "휴지통으로 이동 호출 횟수가 일치하지 않습니다.",
                file: file,
                line: line
            )
        }
        if let expected = expectedMoveAllToWasteBasketCallCount {
            XCTAssertEqual(
                moveAllToWasteBasketCallCount,
                expected,
                "전체 휴지통으로 이동 호출 횟수가 일치하지 않습니다.",
                file: file,
                line: line
            )
        }
        if let expected = expectedDeleteCallCount {
            XCTAssertEqual(deleteCallCount, expected, "삭제 호출 횟수가 일치하지 않습니다.", file: file, line: line)
        }
        if let expected = expectedDeleteAllCallCount {
            XCTAssertEqual(deleteAllCallCount, expected, "전체 삭제 호출 횟수가 일치하지 않습니다.", file: file, line: line)
        }
        if let expected = expectedAllClearCallCount {
            XCTAssertEqual(allClearCallCount, expected, "비우기 호출 횟수가 일치하지 않습니다.", file: file, line: line)
        }

        // Argument Verification
        if let expected = expectedLastMovedItem {
            XCTAssertEqual(lastMovedItem, expected, "마지막으로 이동된 항목이 일치하지 않습니다.", file: file, line: line)
        }
        if let expected = expectedLastMovedItems {
            XCTAssertEqual(lastMovedItems, expected, "마지막으로 이동된 항목 목록이 일치하지 않습니다.", file: file, line: line)
        }
        if let expected = expectedLastDeletedItem {
            XCTAssertEqual(lastDeletedItem, expected, "마지막으로 삭제된 항목이 일치하지 않습니다.", file: file, line: line)
        }
        if let expected = expectedLastDeletedItems {
            XCTAssertEqual(lastDeletedItems, expected, "마지막으로 삭제된 항목 목록이 일치하지 않습니다.", file: file, line: line)
        }
    }

    // MARK: - WasteBasketRepository (Fetch, Move, Delete)

    func fetchAll() async throws(FetchWasteBasketRepositoryError) -> [WasteBasketItem] {
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

    func moveToWasteBasket(item: WasteBasketItem) async throws(MoveWasteBasketRepositoryError) {
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

    func moveAllToWasteBasket(items: [WasteBasketItem]) async throws(MoveWasteBasketRepositoryError) {
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

    func delete(item: WasteBasketItem) async throws(DeleteWasteBasketRepositoryError) {
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

    func deleteAll(items: [WasteBasketItem]) async throws(DeleteWasteBasketRepositoryError) {
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

    func allClear() async throws(DeleteWasteBasketRepositoryError) {
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
}
