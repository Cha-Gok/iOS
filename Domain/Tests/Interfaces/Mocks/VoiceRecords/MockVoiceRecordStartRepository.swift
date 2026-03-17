@testable import Domain
import Core
import XCTest

actor MockVoiceRecordStartRepository: VoiceRecordStartRepository {
    private var result: Result<AsyncStream<Waveform>, VoiceRecordStartRepositoryError>?

    private var actualStartRecordingCallCount = 0
    private var expectedStartRecordingCallCount: Int?

    func setResult(_ result: Result<AsyncStream<Waveform>, VoiceRecordStartRepositoryError>) {
        self.result = result
    }

    func expectStartRecording(callCount: Int) {
        expectedStartRecordingCallCount = callCount
    }

    func verify(file: StaticString = #filePath, line: UInt = #line) {
        if let expected = expectedStartRecordingCallCount {
            XCTAssertEqual(
                actualStartRecordingCallCount,
                expected,
                "startRecording callCount",
                file: file,
                line: line
            )
        }
    }

    func startRecording() async throws(VoiceRecordStartRepositoryError) -> AsyncStream<Waveform> {
        actualStartRecordingCallCount += 1

        switch result {
        case .success(let stream):
            return stream
        case .failure(let error):
            throw error
        case .none:
            XCTFail("MockVoiceRecordStartRepository.result 가 설정되지 않았습니다.")
            throw .unknown(NSError(domain: "MockVoiceRecordStartRepository.result", code: -1))
        }
    }
}
