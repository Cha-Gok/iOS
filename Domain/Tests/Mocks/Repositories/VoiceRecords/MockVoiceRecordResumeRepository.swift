import XCTest

@testable import Domain

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
                "resumeRecording callCount",
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
