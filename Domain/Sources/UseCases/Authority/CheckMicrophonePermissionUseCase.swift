import Core
import Foundation

/// 녹음 전 마이크 권한 확인을 위한 유즈케이스
public protocol CheckMicrophonePermissionUseCase: Sendable {
    /// 마이크 권한을 요청 또는 확인합니다.
    /// - Throws: `CheckMicrophonePermissionUseCaseError`
    func execute() async throws(CheckMicrophonePermissionUseCaseError) -> PermissionStatus
}

/// 녹음 전 마이크 권한을 요청 또는 확인 합니다.
public struct DefaultCheckMicrophonePermissionUseCase: CheckMicrophonePermissionUseCase {
    private let repository: MicrophonePermissionRepository

    public init(repository: MicrophonePermissionRepository) {
        self.repository = repository
    }

    public func execute() async throws(CheckMicrophonePermissionUseCaseError) -> PermissionStatus {
        if Task.isCancelled { throw .cancelled }

        do {
            return try await repository.checkMicrophonePermission()
        } catch {
            AppLogger.error(error)
            throw CheckMicrophonePermissionUseCaseError(error)
        }
    }
}

fileprivate extension CheckMicrophonePermissionUseCaseError {
    init(_ error: MicrophonePermissionRepositoryError) {
        switch error {
        case .cancelled: self = .cancelled
        case .unknown(let error): self = .unknown(error)
        }
    }
}
