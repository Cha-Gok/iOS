@testable import Domain
import XCTest

actor MockSTTPermissionRepository: STTPermissionRepository {
    private var result: Result<PermissionStatus, STTPermissionRepositoryError>?

    private var actualCheckSTTPermissionCallCount = 0
    private var expectedCheckSTTPermissionCallCount: Int?

    func setResult(_ result: Result<PermissionStatus, STTPermissionRepositoryError>) {
        self.result = result
    }

    func expectCheckSTTPermission(callCount: Int) {
        expectedCheckSTTPermissionCallCount = callCount
    }

    func verify(file: StaticString = #filePath, line: UInt = #line) {
        if let expected = expectedCheckSTTPermissionCallCount {
            XCTAssertEqual(
                actualCheckSTTPermissionCallCount,
                expected,
                "STT 권한 확인 호출 횟수가 일치하지 않습니다.",
                file: file,
                line: line
            )
        }
    }

    func checkSTTPermission() async throws(STTPermissionRepositoryError) -> PermissionStatus {
        actualCheckSTTPermissionCallCount += 1

        switch result {
        case .success(let state):
            return state
        case .failure(let error):
            throw error
        case .none:
            XCTFail("MockSTTPermissionRepository.result 가 설정되지 않았습니다.")
            throw .unknown(NSError(domain: "MockSTTPermissionRepository.result", code: -1))
        }
    }
}
