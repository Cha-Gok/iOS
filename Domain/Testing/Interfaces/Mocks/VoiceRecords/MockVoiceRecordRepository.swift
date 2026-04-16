@testable import Domain
import Core
import XCTest

public actor MockVoiceRecordRepository: VoiceRecordRepository {
    public init() {}

    private var startResult: Result<AsyncStream<Waveform>, VoiceRecordRepositoryError>?
    private var pauseResult: Result<Void, VoiceRecordRepositoryError>?
    private var resumeResult: Result<Void, VoiceRecordRepositoryError>?
    private var finishResult: Result<VoiceRecord, VoiceRecordRepositoryError>?
    private var cancelResult: Result<Void, VoiceRecordRepositoryError>?
    private nonisolated(unsafe) var checkPermissionResult: PermissionStatus?
    private var requestPermissionResult: Result<PermissionStatus, VoiceRecordRepositoryError>?

    private var actualStartRecordingCallCount = 0
    private var actualPauseRecordingCallCount = 0
    private var actualResumeRecordingCallCount = 0
    private var actualFinishRecordingCallCount = 0
    private var actualCancelRecordingCallCount = 0
    private nonisolated(unsafe) var actualCheckPermissionCallCount = 0
    private var actualRequestPermissionCallCount = 0

    private var expectedStartRecordingCallCount: Int?
    private var expectedPauseRecordingCallCount: Int?
    private var expectedResumeRecordingCallCount: Int?
    private var expectedFinishRecordingCallCount: Int?
    private var expectedCancelRecordingCallCount: Int?
    private nonisolated(unsafe) var expectedCheckPermissionCallCount: Int?
    private var expectedRequestPermissionCallCount: Int?

    public func setStartResult(_ result: Result<AsyncStream<Waveform>, VoiceRecordRepositoryError>) {
        startResult = result
    }

    public func setPauseResult(_ result: Result<Void, VoiceRecordRepositoryError>) {
        pauseResult = result
    }

    public func setResumeResult(_ result: Result<Void, VoiceRecordRepositoryError>) {
        resumeResult = result
    }

    public func setFinishResult(_ result: Result<VoiceRecord, VoiceRecordRepositoryError>) {
        finishResult = result
    }

    public func setCancelResult(_ result: Result<Void, VoiceRecordRepositoryError>) {
        cancelResult = result
    }

    public func setCheckPermissionResult(_ result: PermissionStatus) {
        checkPermissionResult = result
    }

    public func setRequestPermissionResult(_ result: Result<PermissionStatus, VoiceRecordRepositoryError>) {
        requestPermissionResult = result
    }

    public func expectStartRecording(callCount: Int) {
        expectedStartRecordingCallCount = callCount
    }

    public func expectPauseRecording(callCount: Int) {
        expectedPauseRecordingCallCount = callCount
    }

    public func expectResumeRecording(callCount: Int) {
        expectedResumeRecordingCallCount = callCount
    }

    public func expectFinishRecording(callCount: Int) {
        expectedFinishRecordingCallCount = callCount
    }

    public func expectCancelRecording(callCount: Int) {
        expectedCancelRecordingCallCount = callCount
    }

    public func expectCheckPermission(callCount: Int) {
        expectedCheckPermissionCallCount = callCount
    }

    public func expectRequestPermission(callCount: Int) {
        expectedRequestPermissionCallCount = callCount
    }

    public func verify(file: StaticString = #filePath, line: UInt = #line) {
        assertCount(actualStartRecordingCallCount, expectedStartRecordingCallCount, "startRecording", file, line)
        assertCount(actualPauseRecordingCallCount, expectedPauseRecordingCallCount, "pauseRecording", file, line)
        assertCount(actualResumeRecordingCallCount, expectedResumeRecordingCallCount, "resumeRecording", file, line)
        assertCount(actualFinishRecordingCallCount, expectedFinishRecordingCallCount, "finishRecording", file, line)
        assertCount(actualCancelRecordingCallCount, expectedCancelRecordingCallCount, "cancelRecording", file, line)
        assertCount(
            actualCheckPermissionCallCount, expectedCheckPermissionCallCount,
            "checkMicrophonePermission", file, line
        )
        assertCount(
            actualRequestPermissionCallCount, expectedRequestPermissionCallCount,
            "requestMicrophonePermission", file, line
        )
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

    public func startRecording() async throws(VoiceRecordRepositoryError) -> AsyncStream<Waveform> {
        if Task.isCancelled { throw .cancelled }
        actualStartRecordingCallCount += 1
        switch startResult {
        case .success(let stream): return stream
        case .failure(let error): throw error
        case .none:
            XCTFail("MockVoiceRecordRepository.startResult 미설정")
            throw .unknown(NSError(domain: "Mock", code: -1))
        }
    }

    public func pauseRecording() async throws(VoiceRecordRepositoryError) {
        if Task.isCancelled { throw .cancelled }
        actualPauseRecordingCallCount += 1
        switch pauseResult {
        case .success: return
        case .failure(let error): throw error
        case .none:
            XCTFail("MockVoiceRecordRepository.pauseResult 미설정")
            throw .unknown(NSError(domain: "Mock", code: -1))
        }
    }

    public func resumeRecording() async throws(VoiceRecordRepositoryError) {
        if Task.isCancelled { throw .cancelled }
        actualResumeRecordingCallCount += 1
        switch resumeResult {
        case .success: return
        case .failure(let error): throw error
        case .none:
            XCTFail("MockVoiceRecordRepository.resumeResult 미설정")
            throw .unknown(NSError(domain: "Mock", code: -1))
        }
    }

    public func finishRecording() async throws(VoiceRecordRepositoryError) -> VoiceRecord {
        if Task.isCancelled { throw .cancelled }
        actualFinishRecordingCallCount += 1
        switch finishResult {
        case .success(let record): return record
        case .failure(let error): throw error
        case .none:
            XCTFail("MockVoiceRecordRepository.finishResult 미설정")
            throw .unknown(NSError(domain: "Mock", code: -1))
        }
    }

    public func cancelRecording() async throws(VoiceRecordRepositoryError) {
        if Task.isCancelled { throw .cancelled }
        actualCancelRecordingCallCount += 1
        switch cancelResult {
        case .success: return
        case .failure(let error): throw error
        case .none:
            XCTFail("MockVoiceRecordRepository.cancelResult 미설정")
            throw .unknown(NSError(domain: "Mock", code: -1))
        }
    }

    public nonisolated func checkMicrophonePermission() -> PermissionStatus {
        actualCheckPermissionCallCount += 1
        if let checkPermissionResult {
            return checkPermissionResult
        }
        XCTFail("MockVoiceRecordRepository.checkPermissionResult 미설정")
        return .notDetermined
    }

    public func requestMicrophonePermission() async throws(VoiceRecordRepositoryError) -> PermissionStatus {
        if Task.isCancelled { throw .cancelled }
        actualRequestPermissionCallCount += 1
        switch requestPermissionResult {
        case .success(let state): return state
        case .failure(let error): throw error
        case .none:
            XCTFail("MockVoiceRecordRepository.requestPermissionResult 미설정")
            throw .unknown(NSError(domain: "Mock", code: -1))
        }
    }
}
