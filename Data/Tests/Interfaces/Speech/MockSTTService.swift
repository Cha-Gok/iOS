@testable import Data
import XCTest

actor MockSTTService: STTService {
    private var result: Result<String, STTServiceError>?

    private var actualCallCount = 0
    private var actualAudioFileURL: URL?

    private var expectedCallCount: Int?
    private var expectedAudioFileURL: URL?

    func setResult(_ result: Result<String, STTServiceError>) {
        self.result = result
    }

    func expectTranscribe(callCount: Int, audioFileURL: URL? = nil) {
        expectedCallCount = callCount
        expectedAudioFileURL = audioFileURL
    }

    func verify(file: StaticString = #filePath, line: UInt = #line) {
        if let expected = expectedCallCount {
            XCTAssertEqual(
                actualCallCount,
                expected,
                "전사 호출 횟수가 일치하지 않습니다.",
                file: file,
                line: line
            )
        }
        if let expectedURL = expectedAudioFileURL {
            XCTAssertEqual(
                actualAudioFileURL,
                expectedURL,
                "전사 오디오 파일 URL이 일치하지 않습니다.",
                file: file,
                line: line
            )
        }
    }

    func transcribe(audioFileURL: URL) async throws(STTServiceError) -> String {
        actualCallCount += 1
        actualAudioFileURL = audioFileURL
        switch result {
        case .success(let text):
            return text
        case .failure(let error):
            throw error
        case .none:
            XCTFail("MockSTTService.result 가 설정되지 않았습니다.")
            throw .unknown(NSError(domain: "MockSTTService", code: -1))
        }
    }
}
