@testable import Domain
import Core
import XCTest

actor MockVoiceRecordRepository: VoiceRecordRepository {
    private var startResult: Result<AsyncStream<Waveform>, VoiceRecordRepositoryError>?
    private var pauseResult: Result<Void, VoiceRecordRepositoryError>?
    private var resumeResult: Result<Void, VoiceRecordRepositoryError>?
    private var finishResult: Result<VoiceRecord, VoiceRecordRepositoryError>?
    private var checkPermissionResult: Result<PermissionStatus, VoiceRecordRepositoryError>?
    private var requestPermissionResult: Result<PermissionStatus, VoiceRecordRepositoryError>?

    private var actualStartRecordingCallCount = 0
    private var actualPauseRecordingCallCount = 0
    private var actualResumeRecordingCallCount = 0
    private var actualFinishRecordingCallCount = 0
    private var actualCheckPermissionCallCount = 0
    private var actualRequestPermissionCallCount = 0

    private var expectedStartRecordingCallCount: Int?
    private var expectedPauseRecordingCallCount: Int?
    private var expectedResumeRecordingCallCount: Int?
    private var expectedFinishRecordingCallCount: Int?
    private var expectedCheckPermissionCallCount: Int?
    private var expectedRequestPermissionCallCount: Int?

    func setStartResult(_ result: Result<AsyncStream<Waveform>, VoiceRecordRepositoryError>) {
        startResult = result
    }

    func setPauseResult(_ result: Result<Void, VoiceRecordRepositoryError>) {
        pauseResult = result
    }

    func setResumeResult(_ result: Result<Void, VoiceRecordRepositoryError>) {
        resumeResult = result
    }

    func setFinishResult(_ result: Result<VoiceRecord, VoiceRecordRepositoryError>) {
        finishResult = result
    }

    func setCheckPermissionResult(_ result: Result<PermissionStatus, VoiceRecordRepositoryError>) {
        checkPermissionResult = result
    }

    func setRequestPermissionResult(_ result: Result<PermissionStatus, VoiceRecordRepositoryError>) {
        requestPermissionResult = result
    }

    func expectStartRecording(callCount: Int) {
        expectedStartRecordingCallCount = callCount
    }

    func expectPauseRecording(callCount: Int) {
        expectedPauseRecordingCallCount = callCount
    }

    func expectResumeRecording(callCount: Int) {
        expectedResumeRecordingCallCount = callCount
    }

    func expectFinishRecording(callCount: Int) {
        expectedFinishRecordingCallCount = callCount
    }

    func expectCheckPermission(callCount: Int) {
        expectedCheckPermissionCallCount = callCount
    }

    func expectRequestPermission(callCount: Int) {
        expectedRequestPermissionCallCount = callCount
    }

    func verify(file: StaticString = #filePath, line: UInt = #line) {
        if let expected = expectedStartRecordingCallCount {
            XCTAssertEqual(actualStartRecordingCallCount, expected, "startRecording 호출 횟수 불일치", file: file, line: line)
        }
        if let expected = expectedPauseRecordingCallCount {
            XCTAssertEqual(actualPauseRecordingCallCount, expected, "pauseRecording 호출 횟수 불일치", file: file, line: line)
        }
        if let expected = expectedResumeRecordingCallCount {
            XCTAssertEqual(
                actualResumeRecordingCallCount,
                expected,
                "resumeRecording 호출 횟수 불일치",
                file: file,
                line: line
            )
        }
        if let expected = expectedFinishRecordingCallCount {
            XCTAssertEqual(
                actualFinishRecordingCallCount,
                expected,
                "finishRecording 호출 횟수 불일치",
                file: file,
                line: line
            )
        }
        if let expected = expectedCheckPermissionCallCount {
            XCTAssertEqual(
                actualCheckPermissionCallCount,
                expected,
                "checkMicrophonePermission 호출 횟수 불일치",
                file: file,
                line: line
            )
        }
        if let expected = expectedRequestPermissionCallCount {
            XCTAssertEqual(
                actualRequestPermissionCallCount,
                expected,
                "requestMicrophonePermission 호출 횟수 불일치",
                file: file,
                line: line
            )
        }
    }

    func startRecording() async throws(VoiceRecordRepositoryError) -> AsyncStream<Waveform> {
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

    func pauseRecording() async throws(VoiceRecordRepositoryError) {
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

    func resumeRecording() async throws(VoiceRecordRepositoryError) {
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

    func finishRecording() async throws(VoiceRecordRepositoryError) -> VoiceRecord {
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

    func checkMicrophonePermission() async throws(VoiceRecordRepositoryError) -> PermissionStatus {
        if Task.isCancelled { throw .cancelled }
        actualCheckPermissionCallCount += 1
        switch checkPermissionResult {
        case .success(let state): return state
        case .failure(let error): throw error
        case .none:
            XCTFail("MockVoiceRecordRepository.checkPermissionResult 미설정")
            throw .unknown(NSError(domain: "Mock", code: -1))
        }
    }

    func requestMicrophonePermission() async throws(VoiceRecordRepositoryError) -> PermissionStatus {
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
