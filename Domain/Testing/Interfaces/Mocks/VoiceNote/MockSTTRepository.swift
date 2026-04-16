@testable import Domain
import Foundation
import XCTest

public actor MockSTTRepository: STTRepository {
    public init() {}

    private var result: Result<Transcript, STTRepositoryError>?
    nonisolated(unsafe) private var checkResult: PermissionStatus?
    private var requestResult: Result<PermissionStatus, STTPermissionRepositoryError>?

    private var actualCallCount = 0
    private var actualAudioFilePath: String?
    nonisolated(unsafe) private var actualCheckSTTPermissionCallCount = 0
    private var actualRequestSTTPermissionCallCount = 0

    private var expectedCallCount: Int?
    private var expectedAudioFilePath: String?
    nonisolated(unsafe) private var expectedCheckSTTPermissionCallCount: Int?
    private var expectedRequestSTTPermissionCallCount: Int?

    public func setResult(_ result: Result<Transcript, STTRepositoryError>) {
        self.result = result
    }

    public func setCheckResult(_ result: PermissionStatus) {
        checkResult = result
    }

    public func setRequestResult(_ result: Result<PermissionStatus, STTPermissionRepositoryError>) {
        requestResult = result
    }

    public func expectTranscribe(callCount: Int, audioFilePath: String? = nil) {
        expectedCallCount = callCount
        expectedAudioFilePath = audioFilePath
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
        if let expectedPath = expectedAudioFilePath {
            XCTAssertEqual(
                actualAudioFilePath, expectedPath, "변환 오디오 파일 경로가 일치하지 않습니다.", file: file, line: line
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

    public func transcribe(audioFilePath: String) async throws(STTRepositoryError) -> Transcript {
        actualCallCount += 1
        actualAudioFilePath = audioFilePath

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

    public nonisolated func checkSTTPermission() -> PermissionStatus {
        actualCheckSTTPermissionCallCount += 1
        if let checkResult {
            return checkResult
        }
        XCTFail("MockSTTRepository.checkResult 가 설정되지 않았습니다.")
        return .notDetermined
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
