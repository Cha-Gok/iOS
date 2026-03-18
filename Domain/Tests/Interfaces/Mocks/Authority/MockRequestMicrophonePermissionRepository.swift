@testable import Domain
import XCTest

actor MockRequestMicrophonePermissionRepository: RequestMicrophonePermissionRepository {
    private var result: Result<PermissionStatus, RequestMicrophonePermissionRepositoryError>?

    private var actualRequestMicrophonePermissionCallCount = 0
    private var expectedRequestMicrophonePermissionCallCount: Int?

    func setResult(_ result: Result<PermissionStatus, RequestMicrophonePermissionRepositoryError>) {
        self.result = result
    }

    func expectRequestMicrophonePermission(callCount: Int) {
        expectedRequestMicrophonePermissionCallCount = callCount
    }

    func verify(file: StaticString = #filePath, line: UInt = #line) {
        if let expected = expectedRequestMicrophonePermissionCallCount {
            XCTAssertEqual(
                actualRequestMicrophonePermissionCallCount,
                expected,
                "마이크 권한 요청 호출 횟수가 일치하지 않습니다.",
                file: file,
                line: line
            )
        }
    }

    func requestMicrophonePermission() async throws(RequestMicrophonePermissionRepositoryError)
        -> PermissionStatus
    {
        actualRequestMicrophonePermissionCallCount += 1

        switch result {
        case .success(let status):
            return status
        case .failure(let error):
            throw error
        case .none:
            XCTFail("MockRequestMicrophonePermissionRepository.result 가 설정되지 않았습니다.")
            throw .unknown(NSError(domain: "MockRequestMicrophonePermissionRepository.result", code: -1))
        }
    }
}
