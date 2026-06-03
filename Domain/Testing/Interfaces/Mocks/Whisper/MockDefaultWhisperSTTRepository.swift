@testable import Domain
import Foundation
import XCTest

public actor MockDefaultWhisperSTTRepository: STTRepository {
    public init() {}

    private var transcribeResult: Result<Transcript, STTRepositoryError>?
    private nonisolated(unsafe) var checkSTTPermissionResult: PermissionStatus?
    private var requestSTTPermissionResult: Result<PermissionStatus, STTPermissionRepositoryError>?
    private var downloadResult: Result<URL, STTRepositoryError>?

    private var actualTranscribeCallCount = 0
    private nonisolated(unsafe) var actualCheckSTTPermissionCallCount = 0
    private var actualRequestSTTPermissionCallCount = 0
    private var actualDownloadCallCount = 0

    private var expectedTranscribeCallCount: Int?
    private nonisolated(unsafe) var expectedCheckSTTPermissionCallCount: Int?
    private var expectedRequestSTTPermissionCallCount: Int?
    private var expectedDownloadCallCount: Int?

    public func setTranscribeResult(_ result: Result<Transcript, STTRepositoryError>) {
        transcribeResult = result
    }

    public func setCheckSTTPermissionResult(_ result: PermissionStatus) {
        checkSTTPermissionResult = result
    }

    public func setRequestSTTPermissionResult(_ result: Result<PermissionStatus, STTPermissionRepositoryError>) {
        requestSTTPermissionResult = result
    }

    public func setDownloadResult(_ result: Result<URL, STTRepositoryError>) {
        downloadResult = result
    }

    public func expectTranscribe(callCount: Int) {
        expectedTranscribeCallCount = callCount
    }

    public func expectCheckSTTPermission(callCount: Int) {
        expectedCheckSTTPermissionCallCount = callCount
    }

    public func expectRequestSTTPermission(callCount: Int) {
        expectedRequestSTTPermissionCallCount = callCount
    }

    public func expectDownload(callCount: Int) {
        expectedDownloadCallCount = callCount
    }

    public func verify(file: StaticString = #filePath, line: UInt = #line) {
        assertCount(actualTranscribeCallCount, expectedTranscribeCallCount, "transcribe", file, line)
        assertCount(
            actualCheckSTTPermissionCallCount,
            expectedCheckSTTPermissionCallCount,
            "checkSTTPermission",
            file,
            line
        )
        assertCount(
            actualRequestSTTPermissionCallCount,
            expectedRequestSTTPermissionCallCount,
            "requestSTTPermission",
            file,
            line
        )
        assertCount(actualDownloadCallCount, expectedDownloadCallCount, "download", file, line)
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

    public func transcribe(audioFilePath: String) async throws(STTRepositoryError) -> Transcript {
        if Task.isCancelled { throw .cancelled }
        actualTranscribeCallCount += 1

        switch transcribeResult {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        case .none:
            XCTFail("MockDefaultWhisperSTTRepository.transcribeResult 미설정")
            throw .unknown(NSError(domain: "Mock", code: -1))
        }
    }

    public nonisolated func checkSTTPermission() -> PermissionStatus {
        actualCheckSTTPermissionCallCount += 1
        if let result = checkSTTPermissionResult {
            return result
        }
        XCTFail("MockDefaultWhisperSTTRepository.checkSTTPermissionResult 미설정")
        return .notDetermined
    }

    public func requestSTTPermission() async throws(STTPermissionRepositoryError) -> PermissionStatus {
        if Task.isCancelled { throw .cancelled }
        actualRequestSTTPermissionCallCount += 1

        switch requestSTTPermissionResult {
        case .success(let state):
            return state
        case .failure(let error):
            throw error
        case .none:
            XCTFail("MockDefaultWhisperSTTRepository.requestSTTPermissionResult 미설정")
            throw .unknown(NSError(domain: "Mock", code: -1))
        }
    }

    @discardableResult
    public func download(
        progressHandler: (@Sendable (Progress) -> Void)? = nil
    ) async throws(STTRepositoryError) -> URL {
        if Task.isCancelled { throw .cancelled }
        actualDownloadCallCount += 1

        switch downloadResult {
        case .success(let url):
            return url
        case .failure(let error):
            throw error
        case .none:
            XCTFail("MockDefaultWhisperSTTRepository.downloadResult 미설정")
            throw .unknown(NSError(domain: "Mock", code: -1))
        }
    }
}
