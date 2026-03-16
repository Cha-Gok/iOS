import XCTest

@testable import Domain

actor MockMicrophonePermissionRepository: MicrophonePermissionRepository {

    private var result: Result<PermissionStatus, MicrophonePermissionRepositoryError>?

    private var actualCheckRecordingPermissionCallCount = 0
    private var expectedCheckRecordingPermissionCallCount: Int?

    func setResult(_ result: Result<PermissionStatus, MicrophonePermissionRepositoryError>) {
        self.result = result
    }

    func expectCheckRecordingPermission(callCount: Int) {
        expectedCheckRecordingPermissionCallCount = callCount
    }

    func verify(file: StaticString = #filePath, line: UInt = #line) {
        if let expected = expectedCheckRecordingPermissionCallCount {
            XCTAssertEqual(
                actualCheckRecordingPermissionCallCount,
                expected,
                "checkRecordingPermission callCount",
                file: file,
                line: line
            )
        }
    }

    func checkMicrophonePermission() async throws(MicrophonePermissionRepositoryError)
        -> PermissionStatus {
        actualCheckRecordingPermissionCallCount += 1

        switch result {
        case .success(let result):
            return result
        case .failure(let error):
            throw error
        case .none:
            XCTFail("MockVoiceRecordPermissionRepository.result 가 설정되지 않았습니다.")
            throw .unknown(NSError(domain: "MockVoiceRecordPermissionRepository.result", code: -1))
        }
    }
}
