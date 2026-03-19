@testable import Data
import Domain
import XCTest

actor MockAudioRecorderService: AudioRecorderService {
    private var startResult: Result<AsyncStream<Waveform>, Error>?
    private var startCallCount = 0
    private var expectedStartCallCount: Int?

    func setStartResult(_ result: Result<AsyncStream<Waveform>, Error>) {
        startResult = result
    }

    func expectStart(callCount: Int) {
        expectedStartCallCount = callCount
    }

    func verify(file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(startCallCount, expectedStartCallCount, file: file, line: line)
    }

    func startRecording() async throws -> AsyncStream<Waveform> {
        startCallCount += 1
        return try startResult!.get()
    }
}
