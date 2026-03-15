import XCTest

@testable import Domain

actor MockVoiceRecordPermissionRepository: VoiceRecordPermissionRepository {

    private var result: Result<Void, VoiceRecordPermissionRepositoryError>?

    private var actualCheckRecordingPermissionCallCount = 0
    private var expectedCheckRecordingPermissionCallCount: Int?

    func setResult(_ result: Result<Void, VoiceRecordPermissionRepositoryError>) {
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

    func checkRecordingPermission() async throws(VoiceRecordPermissionRepositoryError) {
        actualCheckRecordingPermissionCallCount += 1

        switch result {
        case .success:
            return
        case .failure(let error):
            throw error
        case .none:
            XCTFail("MockVoiceRecordPermissionRepository.result 가 설정되지 않았습니다.")
            throw .unknown(NSError(domain: "MockVoiceRecordPermissionRepository.result", code: -1))
        }
    }
}
