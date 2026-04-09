@testable import Domain
import Foundation
import XCTest

public actor MockSTTRepository: STTRepository {
    public init() {}

    private var result: Result<Transcript, STTRepositoryError>?
    private var checkResult: Result<PermissionStatus, STTPermissionRepositoryError>?
    private var requestResult: Result<PermissionStatus, STTPermissionRepositoryError>?

    private var actualCallCount = 0
    private var actualAudioFileURL: URL?
    private var actualCheckSTTPermissionCallCount = 0
    private var actualRequestSTTPermissionCallCount = 0

    private var expectedCallCount: Int?
    private var expectedAudioFileURL: URL?
    private var expectedCheckSTTPermissionCallCount: Int?
    private var expectedRequestSTTPermissionCallCount: Int?

    public func setResult(_ result: Result<Transcript, STTRepositoryError>) {
        self.result = result
    }

    public func setCheckResult(_ result: Result<PermissionStatus, STTPermissionRepositoryError>) {
        checkResult = result
    }

    public func setRequestResult(_ result: Result<PermissionStatus, STTPermissionRepositoryError>) {
        requestResult = result
    }

    public func expectTranscribe(callCount: Int, audioFileURL: URL? = nil) {
        expectedCallCount = callCount
        expectedAudioFileURL = audioFileURL
    }

    public func expectCheckSTTPermission(callCount: Int) {
        expectedCheckSTTPermissionCallCount = callCount
    }

    public func expectRequestSTTPermission(callCount: Int) {
        expectedRequestSTTPermissionCallCount = callCount
    }

    public func verify(file: StaticString = #filePath, line: UInt = #line) {
        if let expected = expectedCallCount {
            XCTAssertEqual(
                actualCallCount, expected, "변환 호출 횟수가 일치하지 않습니다.", file: file, line: line
            )
        }
        if let expectedURL = expectedAudioFileURL {
            XCTAssertEqual(
                actualAudioFileURL, expectedURL, "변환 오디오 파일 URL이 일치하지 않습니다.", file: file, line: line
            )
        }
        if let expected = expectedCheckSTTPermissionCallCount {
            XCTAssertEqual(
                actualCheckSTTPermissionCallCount,
                expected,
                "STT 권한 확인 호출 횟수가 일치하지 않습니다.",
                file: file,
                line: line
            )
        }
        if let expected = expectedRequestSTTPermissionCallCount {
            XCTAssertEqual(
                actualRequestSTTPermissionCallCount,
                expected,
                "STT 권한 요청 호출 횟수가 일치하지 않습니다.",
                file: file,
                line: line
            )
        }
    }

    public func transcribe(audioFileURL: URL) async throws(STTRepositoryError) -> Transcript {
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

    public func checkSTTPermission() async throws(STTPermissionRepositoryError) -> PermissionStatus {
        actualCheckSTTPermissionCallCount += 1

        switch checkResult {
        case .success(let state):
            return state
        case .failure(let error):
            throw error
        case .none:
            XCTFail("MockSTTRepository.checkResult 가 설정되지 않았습니다.")
            throw .unknown(NSError(domain: "MockSTTRepository.checkResult", code: -1))
        }
    }

    public func requestSTTPermission() async throws(STTPermissionRepositoryError) -> PermissionStatus {
        actualRequestSTTPermissionCallCount += 1

        switch requestResult {
        case .success(let state):
            return state
        case .failure(let error):
            throw error
        case .none:
            XCTFail("MockSTTRepository.requestResult 가 설정되지 않았습니다.")
            throw .unknown(NSError(domain: "MockSTTRepository.requestResult", code: -1))
        }
    }
}
