@testable import Domain
import Foundation
import XCTest

@MainActor
public final class MockVoiceNoteAnalysisService: VoiceNoteAnalysisService {
    public init() {}

    private var enqueueCallCount = 0
    private var regenerateCallCount = 0
    private var cancelCallCount = 0
    private var cancelAllCallCount = 0

    private var enqueuedIDs: [UUID] = []
    private var regeneratedIDs: [UUID] = []
    private var cancelledIDs: [UUID] = []

    private var expectedEnqueueCallCount: Int?
    private var expectedRegenerateCallCount: Int?
    private var expectedCancelCallCount: Int?
    private var expectedCancelAllCallCount: Int?

    // MARK: - Expectations

    public func expectEnqueue(callCount: Int) {
        expectedEnqueueCallCount = callCount
    }

    public func expectRegenerate(callCount: Int) {
        expectedRegenerateCallCount = callCount
    }

    public func expectCancel(callCount: Int) {
        expectedCancelCallCount = callCount
    }

    public func expectCancelAll(callCount: Int) {
        expectedCancelAllCallCount = callCount
    }

    public func verify(file: StaticString = #filePath, line: UInt = #line) {
        if let expected = expectedEnqueueCallCount {
            XCTAssertEqual(enqueueCallCount, expected, "enqueue 호출 횟수 불일치", file: file, line: line)
        }
        if let expected = expectedRegenerateCallCount {
            XCTAssertEqual(regenerateCallCount, expected, "regenerate 호출 횟수 불일치", file: file, line: line)
        }
        if let expected = expectedCancelCallCount {
            XCTAssertEqual(cancelCallCount, expected, "cancel 호출 횟수 불일치", file: file, line: line)
        }
        if let expected = expectedCancelAllCallCount {
            XCTAssertEqual(cancelAllCallCount, expected, "cancelAll 호출 횟수 불일치", file: file, line: line)
        }
    }

    // MARK: - Protocol

    public func enqueue(voiceNoteID: UUID) {
        enqueueCallCount += 1
        enqueuedIDs.append(voiceNoteID)
    }

    public func regenerate(voiceNoteID: UUID) {
        regenerateCallCount += 1
        regeneratedIDs.append(voiceNoteID)
    }

    public func cancel(voiceNoteID: UUID) {
        cancelCallCount += 1
        cancelledIDs.append(voiceNoteID)
    }

    public func cancelAll() {
        cancelAllCallCount += 1
    }
}
