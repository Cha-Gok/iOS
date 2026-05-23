@testable import Domain
import Foundation
import XCTest

@MainActor
public final class MockDeleteOnDeviceRepository: DeleteOnDeviceRepository {
    public init() {}

    private var whisperModelResult: Result<Void, DeleteOnDeviceRepositoryError>?
    private var mlxModelResult: Result<Void, DeleteOnDeviceRepositoryError>?

    private var actualWhisperModelCallCount = 0
    private var actualMlxModelCallCount = 0

    private var expectedWhisperModelCallCount: Int?
    private var expectedMlxModelCallCount: Int?

    public func setWhisperModelResult(_ result: Result<Void, DeleteOnDeviceRepositoryError>) {
        whisperModelResult = result
    }

    public func setMlxModelResult(_ result: Result<Void, DeleteOnDeviceRepositoryError>) {
        mlxModelResult = result
    }

    public func expectWhisperModel(callCount: Int) {
        expectedWhisperModelCallCount = callCount
    }

    public func expectMlxModel(callCount: Int) {
        expectedMlxModelCallCount = callCount
    }

    public func verify(file: StaticString = #filePath, line: UInt = #line) {
        assertCount(
            actualWhisperModelCallCount,
            expectedWhisperModelCallCount,
            "whisperModel",
            file,
            line
        )
        assertCount(actualMlxModelCallCount, expectedMlxModelCallCount, "mlxModel", file, line)
    }

    private func assertCount(
        _ actual: Int,
        _ expected: Int?,
        _ label: String,
        _ file: StaticString,
        _ line: UInt
    ) {
        guard let expected else { return }
        XCTAssertEqual(actual, expected, "\(label) 호출 횟수 불일치", file: file, line: line)
    }

    public func whisperModel() async throws(DeleteOnDeviceRepositoryError) {
        actualWhisperModelCallCount += 1

        switch whisperModelResult {
        case .success:
            return
        case .failure(let error):
            throw error
        case .none:
            XCTFail("MockDeleteOnDeviceRepository.whisperModelResult 미설정")
            let error = NSError(domain: "MockDeleteOnDeviceRepository.whisperModelResult", code: 0)
            throw .unknown(error)
        }
    }

    public func mlxModel() async throws(DeleteOnDeviceRepositoryError) {
        actualMlxModelCallCount += 1

        switch mlxModelResult {
        case .success:
            return
        case .failure(let error):
            throw error
        case .none:
            XCTFail("MockDeleteOnDeviceRepository.mlxModelResult 미설정")
            let error = NSError(domain: "MockDeleteOnDeviceRepository.mlxModelResult", code: 0)
            throw .unknown(error)
        }
    }
}
