@testable import Data
import Domain
import XCTest

actor MockSTTService: STTService {
    private var transcribeResult: Result<String, STTServiceError>?
    private var checkResult: PermissionStatus?
    private var requestResult: PermissionStatus?

    private var actualTranscribeCallCount = 0
    private var actualTranscribeAudioFileURL: URL?
    private var actualCheckCallCount = 0
    private var actualRequestCallCount = 0

    private var expectedTranscribeCallCount: Int?
    private var expectedTranscribeAudioFileURL: URL?
    private var expectedCheckCallCount: Int?
    private var expectedRequestCallCount: Int?

    func setResult(_ result: Result<String, STTServiceError>) {
        transcribeResult = result
    }

    func setCheckResult(_ status: PermissionStatus) {
        checkResult = status
    }

    func setRequestResult(_ status: PermissionStatus) {
        requestResult = status
    }

    func expectTranscribe(callCount: Int, audioFileURL: URL? = nil) {
        expectedTranscribeCallCount = callCount
        expectedTranscribeAudioFileURL = audioFileURL
    }

    func expectCheck(callCount: Int) {
        expectedCheckCallCount = callCount
    }

    func expectRequest(callCount: Int) {
        expectedRequestCallCount = callCount
    }

    func verify(file: StaticString = #filePath, line: UInt = #line) {
        if let expected = expectedTranscribeCallCount {
            XCTAssertEqual(
                actualTranscribeCallCount,
                expected,
                "전사 호출 횟수가 일치하지 않습니다.",
                file: file,
                line: line
            )
        }
        if let expectedURL = expectedTranscribeAudioFileURL {
            XCTAssertEqual(
                actualTranscribeAudioFileURL,
                expectedURL,
                "전사 오디오 파일 URL이 일치하지 않습니다.",
                file: file,
                line: line
            )
        }
        if let expected = expectedCheckCallCount {
            XCTAssertEqual(
                actualCheckCallCount,
                expected,
                "checkPermission 호출 횟수가 일치하지 않습니다.",
                file: file,
                line: line
            )
        }
        if let expected = expectedRequestCallCount {
            XCTAssertEqual(
                actualRequestCallCount,
                expected,
                "requestPermission 호출 횟수가 일치하지 않습니다.",
                file: file,
                line: line
            )
        }
    }

    func checkPermission() async -> PermissionStatus {
        guard let checkResult else {
            XCTFail("checkResult이 설정되지 않았습니다. setCheckResult()를 먼저 호출하세요.")
            return .notDetermined
        }
        actualCheckCallCount += 1
        return checkResult
    }

    func requestPermission() async -> PermissionStatus {
        guard let requestResult else {
            XCTFail("requestResult이 설정되지 않았습니다. setRequestResult()를 먼저 호출하세요.")
            return .notDetermined
        }
        actualRequestCallCount += 1
        return requestResult
    }

    func transcribe(audioFileURL: URL) async throws(STTServiceError) -> String {
        actualTranscribeCallCount += 1
        actualTranscribeAudioFileURL = audioFileURL
        switch transcribeResult {
        case .success(let text):
            return text
        case .failure(let error):
            throw error
        case .none:
            XCTFail("MockSTTService.transcribeResult 가 설정되지 않았습니다.")
            throw .unknown(NSError(domain: "MockSTTService", code: -1))
        }
    }
}
