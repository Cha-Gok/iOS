import Core
import Foundation

/// 온보딩 과정에서 마이크 권한 확인을 위한 유즈케이스
public protocol CheckMicrophonePermissionUseCase: Sendable {
    /// 마이크 권한을 요청 또는 확인합니다.
    /// - Throws: `VoiceRecordUseCaseError` (권한 거부)
    func execute() async throws(VoiceRecordUseCaseError)
}

/// 온보딩에서 마이크 권한을 요청 또는 확인 합니다.
public struct DefaultCheckMicrophonePermissionUseCase: CheckMicrophonePermissionUseCase {
    private let repository: VoiceRecordRepository

    public init(repository: VoiceRecordRepository) {
        self.repository = repository
    }

    public func execute() async throws(VoiceRecordUseCaseError) {
        do {
            try Task.checkCancellation()
            try await repository.checkRecordingPermission()
        } catch is CancellationError {
            let useCaseError = VoiceRecordUseCaseError.cancelled
            AppLogger.error(useCaseError)
            throw useCaseError
        } catch let error as VoiceRecordRepositoryError {
            AppLogger.error(error)
            throw mapFromRepository(error)
        } catch {
            let useCaseError = VoiceRecordUseCaseError.unknown(error)
            AppLogger.error(useCaseError)
            throw useCaseError
        }
    }

    private func mapFromRepository(_ error: VoiceRecordRepositoryError) -> VoiceRecordUseCaseError {
        switch error {
        case .permissionDenied: return .permissionDenied
        case .cancelled: return .cancelled
        case .startFailed, .notRecording, .notPaused, .pauseFailed, .resumeFailed, .finishFailed,
            .encodingFailed:
            return .unknown(error)
        case .unknown(let error): return .unknown(error)
        }
    }
}
