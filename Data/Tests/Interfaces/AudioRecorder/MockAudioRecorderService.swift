@testable import Data
import Domain
import Foundation
import XCTest

actor MockAudioRecorderService: AudioRecorderService {
    private var startResult: Result<AsyncStream<Waveform>, AudioRecorderServiceError>?
    private var pauseResult: Result<Void, AudioRecorderServiceError>?
    private var resumeResult: Result<Void, AudioRecorderServiceError>?
    private var finishResult: Result<RecordedAudio, AudioRecorderServiceError>?

    private var startCallCount = 0
    private var pauseCallCount = 0
    private var resumeCallCount = 0
    private var finishCallCount = 0

    private var expectedStartCallCount: Int?
    private var expectedPauseCallCount: Int?
    private var expectedResumeCallCount: Int?
    private var expectedFinishCallCount: Int?

    private var checkPermissionResult: PermissionStatus?
    private var requestPermissionResult: PermissionStatus?
    private var checkPermissionCallCount = 0
    private var requestPermissionCallCount = 0
    private var expectedCheckPermissionCallCount: Int?
    private var expectedRequestPermissionCallCount: Int?

    func setStartResult(_ result: Result<AsyncStream<Waveform>, AudioRecorderServiceError>) {
        startResult = result
    }

    func setPauseResult(_ result: Result<Void, AudioRecorderServiceError>) {
        pauseResult = result
    }

    func setResumeResult(_ result: Result<Void, AudioRecorderServiceError>) {
        resumeResult = result
    }

    func setFinishResult(_ result: Result<RecordedAudio, AudioRecorderServiceError>) {
        finishResult = result
    }

    func setCheckResult(_ state: PermissionStatus) {
        checkPermissionResult = state
    }

    func setRequestResult(_ state: PermissionStatus) {
        requestPermissionResult = state
    }

    func expectStart(callCount: Int) {
        expectedStartCallCount = callCount
    }

    func expectPause(callCount: Int) {
        expectedPauseCallCount = callCount
    }

    func expectResume(callCount: Int) {
        expectedResumeCallCount = callCount
    }

    func expectFinish(callCount: Int) {
        expectedFinishCallCount = callCount
    }

    func expectCheckPermission(callCount: Int) {
        expectedCheckPermissionCallCount = callCount
    }

    func expectRequestPermission(callCount: Int) {
        expectedRequestPermissionCallCount = callCount
    }

    func verify(file: StaticString = #filePath, line: UInt = #line) {
        if let expectedStartCallCount {
            XCTAssertEqual(startCallCount, expectedStartCallCount, file: file, line: line)
        }
        if let expectedPauseCallCount {
            XCTAssertEqual(pauseCallCount, expectedPauseCallCount, file: file, line: line)
        }
        if let expectedResumeCallCount {
            XCTAssertEqual(resumeCallCount, expectedResumeCallCount, file: file, line: line)
        }
        if let expectedFinishCallCount {
            XCTAssertEqual(finishCallCount, expectedFinishCallCount, file: file, line: line)
        }
        if let expectedCheckPermissionCallCount {
            XCTAssertEqual(checkPermissionCallCount, expectedCheckPermissionCallCount, file: file, line: line)
        }
        if let expectedRequestPermissionCallCount {
            XCTAssertEqual(requestPermissionCallCount, expectedRequestPermissionCallCount, file: file, line: line)
        }
    }

    func startRecording(at filePath: URL) async throws(AudioRecorderServiceError) -> AsyncStream<Waveform> {
        startCallCount += 1
        guard let startResult else {
            XCTFail("startResult가 설정되지 않았습니다. setStartResult()를 먼저 호출하세요.")
            throw .startFailed
        }
        return try startResult.get()
    }

    func pauseRecording() async throws(AudioRecorderServiceError) {
        pauseCallCount += 1
        guard let pauseResult else {
            XCTFail("pauseResult가 설정되지 않았습니다. setPauseResult()를 먼저 호출하세요.")
            throw .pauseFailed
        }
        _ = try pauseResult.get()
    }

    func resumeRecording() async throws(AudioRecorderServiceError) {
        resumeCallCount += 1
        guard let resumeResult else {
            XCTFail("resumeResult가 설정되지 않았습니다. setResumeResult()를 먼저 호출하세요.")
            throw .resumeFailed
        }
        _ = try resumeResult.get()
    }

    func finishRecording() async throws(AudioRecorderServiceError) -> RecordedAudio {
        finishCallCount += 1
        guard let finishResult else {
            XCTFail("finishResult가 설정되지 않았습니다. setFinishResult()를 먼저 호출하세요.")
            throw .finishFailed
        }
        return try finishResult.get()
    }

    private var currentURLResult: URL?

    func setCurrentURL(_ url: URL?) {
        currentURLResult = url
    }

    func currentRecordingURL() async -> URL? {
        currentURLResult
    }

    func checkPermission() async -> PermissionStatus {
        checkPermissionCallCount += 1
        return checkPermissionResult ?? .notDetermined
    }

    func requestPermission() async -> PermissionStatus {
        requestPermissionCallCount += 1
        return requestPermissionResult ?? .notDetermined
    }
}
