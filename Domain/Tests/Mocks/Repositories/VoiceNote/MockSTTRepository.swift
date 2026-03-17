import Foundation
import XCTest

@testable import Domain

actor MockSTTRepository: STTRepository {

    private var result: Result<Transcript, STTRepositoryError>?

    private(set) var actualCallCount = 0
    private(set) var actualAudioFileURL: URL?

    private var expectedCallCount: Int?
    private var expectedAudioFileURL: URL?

    func setResult(_ result: Result<Transcript, STTRepositoryError>) {
        self.result = result
    }

    func expectTranscribe(callCount: Int, audioFileURL: URL? = nil) {
        expectedCallCount = callCount
        expectedAudioFileURL = audioFileURL
    }

    func verify(file: StaticString = #filePath, line: UInt = #line) {
        if let expected = expectedCallCount {
            XCTAssertEqual(
                actualCallCount, expected, "transcribe callCount", file: file, line: line)
        }
        if let expectedURL = expectedAudioFileURL {
            XCTAssertEqual(
                actualAudioFileURL, expectedURL, "transcribe audioFileURL", file: file, line: line)
        }
    }

    func transcribe(audioFileURL: URL) async throws(STTRepositoryError) -> Transcript {
        actualCallCount += 1
        actualAudioFileURL = audioFileURL

        switch result {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        case .none:
            XCTFail("MockSTTRepository.result 가 설정되지 않았습니다.")
            throw .unknown(
                NSError(domain: "MockSTTRepository.result", code: -1)
            )
        }
    }
}
