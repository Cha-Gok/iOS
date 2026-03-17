@testable import Domain
import XCTest

actor MockMicrophonePermissionRepository: MicrophonePermissionRepository {
    private var result: Result<PermissionStatus, MicrophonePermissionRepositoryError>?

    private var actualCheckMicrophonePermissionCallCount = 0
    private var expectedCheckMicrophonePermissionCallCount: Int?

    func setResult(_ result: Result<PermissionStatus, MicrophonePermissionRepositoryError>) {
        self.result = result
    }

    func expectCheckMicrophonePermission(callCount: Int) {
        expectedCheckMicrophonePermissionCallCount = callCount
    }

    func verify(file: StaticString = #filePath, line: UInt = #line) {
        if let expected = expectedCheckMicrophonePermissionCallCount {
            XCTAssertEqual(
                actualCheckMicrophonePermissionCallCount,
                expected,
                "checkMicrophonePermission callCount",
                file: file,
                line: line
            )
        }
    }

    func checkMicrophonePermission() async throws(MicrophonePermissionRepositoryError)
        -> PermissionStatus
    {
        actualCheckMicrophonePermissionCallCount += 1

        switch result {
        case .success(let state):
            return state
        case .failure(let error):
            throw error
        case .none:
            XCTFail("MockMicrophonePermissionRepository.result 가 설정되지 않았습니다.")
            throw .unknown(NSError(domain: "MockMicrophonePermissionRepository.result", code: -1))
        }
    }
}
