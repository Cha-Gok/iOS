@testable import Domain
import XCTest

actor MockVoiceRecordPauseRepository: VoiceRecordPauseRepository {
    private var result: Result<Void, VoiceRecordPauseRepositoryError>?

    private var actualPauseRecordingCallCount = 0
    private var expectedPauseRecordingCallCount: Int?

    func setResult(_ result: Result<Void, VoiceRecordPauseRepositoryError>) {
        self.result = result
    }

    func expectPauseRecording(callCount: Int) {
        expectedPauseRecordingCallCount = callCount
    }

    func verify(file: StaticString = #filePath, line: UInt = #line) {
        if let expected = expectedPauseRecordingCallCount {
            XCTAssertEqual(
                actualPauseRecordingCallCount,
                expected,
                "녹음 일시정지 호출 횟수가 일치하지 않습니다.",
                file: file,
                line: line
            )
        }
    }

    func pauseRecording() async throws(VoiceRecordPauseRepositoryError) {
        actualPauseRecordingCallCount += 1

        switch result {
        case .success:
            return
        case .failure(let error):
            throw error
        case .none:
            XCTFail("MockVoiceRecordPauseRepository.result 가 설정되지 않았습니다.")
            throw .unknown(NSError(domain: "MockVoiceRecordPauseRepository.result", code: -1))
        }
    }
}
