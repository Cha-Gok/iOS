@testable import Domain
import Foundation
import XCTest

@MainActor
public final class MockTrashUseCase: TrashUseCase, @unchecked Sendable {
    // Results
    private var observeResult: Result<AsyncStream<[ContentItem]>, TrashUseCaseError>?
    // Call counts
    private var moveNoteCallCount = 0
    private var moveFolderCallCount = 0
    private var restoreNoteCallCount = 0
    private var restoreFolderCallCount = 0
    private var hardDeleteNoteCallCount = 0
    private var hardDeleteFolderCallCount = 0
    private var allClearCallCount = 0

    // Captured args
    private var lastMovedNoteID: UUID?
    private var lastMovedFolderID: UUID?
    private var lastRestoredNoteID: UUID?
    private var lastRestoredFolderID: UUID?
    private var lastHardDeletedNoteID: UUID?
    private var lastHardDeletedFolderID: UUID?

    // Expectations
    private var expectedMoveNoteCallCount: Int?
    private var expectedMoveFolderCallCount: Int?
    private var expectedRestoreNoteCallCount: Int?
    private var expectedRestoreFolderCallCount: Int?
    private var expectedHardDeleteNoteCallCount: Int?
    private var expectedHardDeleteFolderCallCount: Int?
    private var expectedAllClearCallCount: Int?

    public init() {}

    // MARK: - Setup

    public func setObserveResult(_ result: Result<AsyncStream<[ContentItem]>, TrashUseCaseError>) {
        observeResult = result
    }

    // MARK: - Expectations

    public func expectMoveToTrash(noteID: UUID? = nil, callCount: Int) {
        lastMovedNoteID = noteID
        expectedMoveNoteCallCount = callCount
    }

    public func expectMoveToTrash(folderID: UUID? = nil, callCount: Int) {
        lastMovedFolderID = folderID
        expectedMoveFolderCallCount = callCount
    }

    public func expectRestoreNote(callCount: Int) { expectedRestoreNoteCallCount = callCount }
    public func expectRestoreFolder(callCount: Int) { expectedRestoreFolderCallCount = callCount }
    public func expectHardDeleteNote(callCount: Int) { expectedHardDeleteNoteCallCount = callCount }
    public func expectHardDeleteFolder(callCount: Int) { expectedHardDeleteFolderCallCount = callCount }
    public func expectAllClear(callCount: Int) { expectedAllClearCallCount = callCount }

    // MARK: - Verify

    public func verify(file: StaticString = #filePath, line: UInt = #line) {
        if let expected = expectedMoveNoteCallCount {
            XCTAssertEqual(moveNoteCallCount, expected, "moveToTrash(noteID:) 호출 횟수 불일치", file: file, line: line)
        }
        if let expected = expectedMoveFolderCallCount {
            XCTAssertEqual(moveFolderCallCount, expected, "moveToTrash(folderID:) 호출 횟수 불일치", file: file, line: line)
        }
        if let expected = expectedRestoreNoteCallCount {
            XCTAssertEqual(restoreNoteCallCount, expected, "restoreNote 호출 횟수 불일치", file: file, line: line)
        }
        if let expected = expectedRestoreFolderCallCount {
            XCTAssertEqual(restoreFolderCallCount, expected, "restoreFolder 호출 횟수 불일치", file: file, line: line)
        }
        if let expected = expectedHardDeleteNoteCallCount {
            XCTAssertEqual(hardDeleteNoteCallCount, expected, "hardDeleteNote 호출 횟수 불일치", file: file, line: line)
        }
        if let expected = expectedHardDeleteFolderCallCount {
            XCTAssertEqual(hardDeleteFolderCallCount, expected, "hardDeleteFolder 호출 횟수 불일치", file: file, line: line)
        }
        if let expected = expectedAllClearCallCount {
            XCTAssertEqual(allClearCallCount, expected, "allClear 호출 횟수 불일치", file: file, line: line)
        }
    }

    // MARK: - TrashUseCase

    public func observe() throws(TrashUseCaseError) -> AsyncStream<[ContentItem]> {
        switch observeResult {
        case .success(let stream): return stream
        case .failure(let error): throw error
        case .none:
            return AsyncStream { $0.finish() }
        }
    }

    public func moveToTrash(noteID: UUID) throws(TrashUseCaseError) {
        moveNoteCallCount += 1
        lastMovedNoteID = noteID
    }

    public func moveToTrash(folderID: UUID) throws(TrashUseCaseError) {
        moveFolderCallCount += 1
        lastMovedFolderID = folderID
    }

    public func restoreNote(id: UUID) throws(TrashUseCaseError) {
        restoreNoteCallCount += 1
        lastRestoredNoteID = id
    }

    public func restoreFolder(id: UUID) throws(TrashUseCaseError) {
        restoreFolderCallCount += 1
        lastRestoredFolderID = id
    }

    public func restore(item: ContentItem) throws(TrashUseCaseError) {
        switch item {
        case .folder(let folder): try restoreFolder(id: folder.id)
        case .voiceNote(let note): try restoreNote(id: note.id)
        }
    }

    public func restoreAll(items: [ContentItem]) throws(TrashUseCaseError) {
        for item in items { try restore(item: item) }
    }

    public func hardDeleteNote(id: UUID) throws(TrashUseCaseError) {
        hardDeleteNoteCallCount += 1
        lastHardDeletedNoteID = id
    }

    public func hardDeleteFolder(id: UUID) throws(TrashUseCaseError) {
        hardDeleteFolderCallCount += 1
        lastHardDeletedFolderID = id
    }

    public func delete(item: ContentItem) throws(TrashUseCaseError) {
        switch item {
        case .folder(let folder): try hardDeleteFolder(id: folder.id)
        case .voiceNote(let note): try hardDeleteNote(id: note.id)
        }
    }

    public func deleteAll(items: [ContentItem]) throws(TrashUseCaseError) {
        for item in items { try delete(item: item) }
    }

    public func allClear() throws(TrashUseCaseError) {
        allClearCallCount += 1
    }
}
