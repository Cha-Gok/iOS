import Core
import Foundation

/// STT 권한 요청을 위한 유스케이스
public protocol RequestSTTPermissionUseCase: Sendable {
    /// STT 권한을 요청합니다.
    /// - Returns: 요청 결과 권한 상태. 이미 거부된 경우 `.denied`를 반환합니다.
    /// - Throws: `RequestSTTPermissionUseCaseError`
    func execute() async throws(RequestSTTPermissionUseCaseError) -> PermissionStatus
}

/// STT 권한을 요청합니다.
public struct DefaultRequestSTTPermissionUseCase: RequestSTTPermissionUseCase {
    private let repository: STTPermissionRepository

    public init(repository: STTPermissionRepository) {
        self.repository = repository
    }

    public func execute() async throws(RequestSTTPermissionUseCaseError) -> PermissionStatus {
        if Task.isCancelled { throw .cancelled }

        do {
            return try await repository.requestSTTPermission()
        } catch {
            AppLogger.error(error)
            throw RequestSTTPermissionUseCaseError(error)
        }
    }
}
