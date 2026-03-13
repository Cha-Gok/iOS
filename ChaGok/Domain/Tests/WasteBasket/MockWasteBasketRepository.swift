import Foundation
import XCTest
@testable import Domain

actor MockWasteBasketRepository: WasteBasketRepository {

    // Results
    private var deleteResult: Result<Void, DeleteWasteBasketRepositoryError>?
    private var moveResult: Result<Void, MoveWasteBasketRepositoryError>?
    private var fetchAllResult: Result<[WasteBasketItem], FetchWasteBasketRepositoryError>?

    // 호출 검증 Count
    private(set) var fetchAllCallCount = 0
    private(set) var moveToWasteBasketCallCount = 0
    private(set) var moveAllToWasteBasketCallCount = 0
    private(set) var deleteCallCount = 0
    private(set) var deleteAllCallCount = 0
    private(set) var allClearCallCount = 0

    // Expected Call Counts
    private var expectedFetchAllCallCount: Int?
    private var expectedMoveToWasteBasketCallCount: Int?
    private var expectedMoveAllToWasteBasketCallCount: Int?
    private var expectedDeleteCallCount: Int?
    private var expectedDeleteAllCallCount: Int?
    private var expectedAllClearCallCount: Int?

    // 받은 인자 기록 (Verification용)
    private(set) var lastMovedItem: WasteBasketItem?
    private(set) var lastMovedItems: [WasteBasketItem]?
    private(set) var lastDeletedItem: WasteBasketItem?
    private(set) var lastDeletedItems: [WasteBasketItem]?

    // MARK: - Setup

    func setFetchAllResult(_ result: Result<[WasteBasketItem], FetchWasteBasketRepositoryError>) {
        self.fetchAllResult = result
    }

    func setMoveResult(_ result: Result<Void, MoveWasteBasketRepositoryError>) {
        self.moveResult = result
    }

    func setDeleteResult(_ result: Result<Void, DeleteWasteBasketRepositoryError>) {
        self.deleteResult = result
    }

    // MARK: - Expectations

    func expectFetchAll(callCount: Int) {
        expectedFetchAllCallCount = callCount
    }

    func expectMoveToWasteBasket(callCount: Int) {
        expectedMoveToWasteBasketCallCount = callCount
    }

    func expectMoveAllToWasteBasket(callCount: Int) {
        expectedMoveAllToWasteBasketCallCount = callCount
    }

    func expectDelete(callCount: Int) {
        expectedDeleteCallCount = callCount
    }

    func expectDeleteAll(callCount: Int) {
        expectedDeleteAllCallCount = callCount
    }

    func expectAllClear(callCount: Int) {
        expectedAllClearCallCount = callCount
    }

    // MARK: - Verification

    func verify(file: StaticString = #filePath, line: UInt = #line) {
        if let expected = expectedFetchAllCallCount {
            XCTAssertEqual(fetchAllCallCount, expected, "fetchAll call count mismatch", file: file, line: line)
        }
        if let expected = expectedMoveToWasteBasketCallCount {
            XCTAssertEqual(moveToWasteBasketCallCount, expected, "moveToWasteBasket call count mismatch", file: file, line: line)
        }
        if let expected = expectedMoveAllToWasteBasketCallCount {
            XCTAssertEqual(moveAllToWasteBasketCallCount, expected, "moveAllToWasteBasket call count mismatch", file: file, line: line)
        }
        if let expected = expectedDeleteCallCount {
            XCTAssertEqual(deleteCallCount, expected, "delete call count mismatch", file: file, line: line)
        }
        if let expected = expectedDeleteAllCallCount {
            XCTAssertEqual(deleteAllCallCount, expected, "deleteAll call count mismatch", file: file, line: line)
        }
        if let expected = expectedAllClearCallCount {
            XCTAssertEqual(allClearCallCount, expected, "allClear call count mismatch", file: file, line: line)
        }
    }

    // MARK: - WasteBasketRepository (Fetch, Move, Delete)

    func fetchAll() async throws(FetchWasteBasketRepositoryError) -> [WasteBasketItem] {
        fetchAllCallCount += 1

        guard let result = fetchAllResult else {
            fatalError("MockWasteBasketRepository.fetchAllResult not set")
        }

        switch result {
            case .success(let items):
                return items
            case .failure(let error):
                throw error
        }
    }

    func moveToWasteBasket(item: WasteBasketItem) async throws(MoveWasteBasketRepositoryError) {
        moveToWasteBasketCallCount += 1
        lastMovedItem = item

        guard let result = moveResult else {
            fatalError("MockWasteBasketRepository.moveResult not set")
        }

        switch result {
            case .success:
                return
            case .failure(let error):
                throw error
        }
    }

    func moveAllToWasteBasket(items: [WasteBasketItem]) async throws(MoveWasteBasketRepositoryError) {
        moveAllToWasteBasketCallCount += 1
        lastMovedItems = items

        guard let result = moveResult else {
            fatalError("MockWasteBasketRepository.moveResult not set")
        }

        switch result {
            case .success:
                return
            case .failure(let error):
                throw error
        }
    }

    func delete(item: WasteBasketItem) async throws(DeleteWasteBasketRepositoryError) {
        deleteCallCount += 1
        lastDeletedItem = item

        guard let result = deleteResult else {
            fatalError("MockWasteBasketRepository.deleteResult not set")
        }

        switch result {
            case .success:
                return
            case .failure(let error):
                throw error
        }
    }

    func deleteAll(items: [WasteBasketItem]) async throws(DeleteWasteBasketRepositoryError) {
        deleteAllCallCount += 1
        lastDeletedItems = items

        guard let result = deleteResult else {
            fatalError("MockWasteBasketRepository.deleteResult not set")
        }

        switch result {
            case .success:
                return
            case .failure(let error):
                throw error
        }
    }

    func allClear() async throws(DeleteWasteBasketRepositoryError) {
        allClearCallCount += 1

        guard let result = deleteResult else {
            fatalError("MockWasteBasketRepository.deleteResult not set")
        }

        switch result {
            case .success:
                return
            case .failure(let error):
                throw error
        }
    }
}
