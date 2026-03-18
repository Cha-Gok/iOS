import Core
import Foundation

/// 녹음 전 STT 권한 확인을 위한 유즈케이스
public protocol CheckSTTPermissionUseCase: Sendable {
    /// STT 권한을 요청 또는 확인합니다.
    /// - Throws: `CheckSTTPermissionUseCaseError` (권한 거부)
    func execute() async throws(CheckSTTPermissionUseCaseError) -> PermissionStatus
}

/// 녹음 전 STT 권한을 요청 또는 확인 합니다.
public struct DefaultCheckSTTPermissionUseCase: CheckSTTPermissionUseCase {
    private let repository: STTPermissionRepository

    public init(repository: STTPermissionRepository) {
        self.repository = repository
    }

    public func execute() async throws(CheckSTTPermissionUseCaseError) -> PermissionStatus {
        if Task.isCancelled { throw .cancelled }

        do {
            return try await repository.checkSTTPermission()
        } catch {
            AppLogger.error(error)
            throw CheckSTTPermissionUseCaseError(error)
        }
    }
}
