@testable import Domain
import XCTest

actor MockRequestSTTPermissionRepository: RequestSTTPermissionRepository {
    private var result: Result<PermissionStatus, RequestSTTPermissionRepositoryError>?

    private var actualRequestSTTPermissionCallCount = 0
    private var expectedRequestSTTPermissionCallCount: Int?

    func setResult(_ result: Result<PermissionStatus, RequestSTTPermissionRepositoryError>) {
        self.result = result
    }

    func expectRequestSTTPermission(callCount: Int) {
        expectedRequestSTTPermissionCallCount = callCount
    }

    func verify(file: StaticString = #filePath, line: UInt = #line) {
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

    func requestSTTPermission() async throws(RequestSTTPermissionRepositoryError) -> PermissionStatus {
        actualRequestSTTPermissionCallCount += 1

        switch result {
        case .success(let status):
            return status
        case .failure(let error):
            throw error
        case .none:
            XCTFail("MockRequestSTTPermissionRepository.result 가 설정되지 않았습니다.")
            throw .unknown(NSError(domain: "MockRequestSTTPermissionRepository.result", code: -1))
        }
    }
}
