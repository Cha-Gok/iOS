@testable import Data
import Domain
import XCTest

actor MockAudioRecorderService: AudioRecorderService {
    private var startResult: Result<AsyncStream<Waveform>, AudioRecorderServiceError>?
    private var startCallCount = 0
    private var expectedStartCallCount: Int?

    func setStartResult(_ result: Result<AsyncStream<Waveform>, AudioRecorderServiceError>) {
        startResult = result
    }

    func expectStart(callCount: Int) {
        expectedStartCallCount = callCount
    }

    func verify(file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(startCallCount, expectedStartCallCount, file: file, line: line)
    }

    func startRecording() async throws(AudioRecorderServiceError) -> AsyncStream<Waveform> {
        startCallCount += 1
        guard let startResult else {
            XCTFail("startResult가 설정되지 않았습니다. setStartResult()를 먼저 호출하세요.")
            throw .startFailed
        }
        return try startResult.get()
    }
}
