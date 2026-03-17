import XCTest

@testable import Domain

actor MockVoiceRecordFinishRepository: VoiceRecordFinishRepository {

    private var result: Result<VoiceRecord, VoiceRecordFinishRepositoryError>?

    private var actualFinishRecordingCallCount = 0
    private var expectedFinishRecordingCallCount: Int?

    func setResult(_ result: Result<VoiceRecord, VoiceRecordFinishRepositoryError>) {
        self.result = result
    }

    func expectFinishRecording(callCount: Int) {
        expectedFinishRecordingCallCount = callCount
    }

    func verify(file: StaticString = #filePath, line: UInt = #line) {
        if let expected = expectedFinishRecordingCallCount {
            XCTAssertEqual(
                actualFinishRecordingCallCount,
                expected,
                "finishRecording callCount",
                file: file,
                line: line
            )
        }
    }

    func finishRecording() async throws(VoiceRecordFinishRepositoryError) -> VoiceRecord {
        actualFinishRecordingCallCount += 1

        switch result {
        case .success(let record):
            return record
        case .failure(let error):
            throw error
        case .none:
            XCTFail("MockVoiceRecordFinishRepository.result 가 설정되지 않았습니다.")
            throw .unknown(NSError(domain: "MockVoiceRecordFinishRepository.result", code: -1))
        }
    }
}
