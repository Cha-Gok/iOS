import Core
import Foundation

/// 녹음 전 마이크 권한 확인을 위한 유즈케이스
public protocol CheckMicrophonePermissionUseCase: Sendable {
    /// 마이크 권한을 요청 또는 확인합니다.
    /// - Throws: `CheckMicrophonePermissionUseCaseError` (권한 거부)
    func execute() async throws(CheckMicrophonePermissionUseCaseError)
}

/// 녹음 전 마이크 권한을 요청 또는 확인 합니다.
public struct DefaultCheckMicrophonePermissionUseCase: CheckMicrophonePermissionUseCase {
    private let repository: VoiceRecordPermissionRepository

    public init(repository: VoiceRecordPermissionRepository) {
        self.repository = repository
    }

    public func execute() async throws(CheckMicrophonePermissionUseCaseError) {
        if Task.isCancelled {
            throw .cancelled
        }

        do {
            try await repository.checkRecordingPermission()
        } catch {
            AppLogger.error(error)
            switch error {
            case .permissionDenied: throw .permissionDenied
            case .cancelled: throw .cancelled
            case .unknown(let error): throw .unknown(error)
            }
        }
    }
}
