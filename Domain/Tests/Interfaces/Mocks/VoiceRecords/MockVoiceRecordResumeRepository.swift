@testable import Domain
import XCTest

actor MockVoiceRecordResumeRepository: VoiceRecordResumeRepository {
    private var result: Result<Void, VoiceRecordResumeRepositoryError>?

    private var actualResumeRecordingCallCount = 0
    private var expectedResumeRecordingCallCount: Int?

    func setResult(_ result: Result<Void, VoiceRecordResumeRepositoryError>) {
        self.result = result
    }

    func expectResumeRecording(callCount: Int) {
        expectedResumeRecordingCallCount = callCount
    }

    func verify(file: StaticString = #filePath, line: UInt = #line) {
        if let expected = expectedResumeRecordingCallCount {
            XCTAssertEqual(
                actualResumeRecordingCallCount,
                expected,
                "녹음 재개 호출 횟수가 일치하지 않습니다.",
                file: file,
                line: line
            )
        }
    }

    func resumeRecording() async throws(VoiceRecordResumeRepositoryError) {
        actualResumeRecordingCallCount += 1

        switch result {
        case .success:
            return
        case .failure(let error):
            throw error
        case .none:
            XCTFail("MockVoiceRecordResumeRepository.result 가 설정되지 않았습니다.")
            throw .unknown(NSError(domain: "MockVoiceRecordResumeRepository.result", code: -1))
        }
    }
}
