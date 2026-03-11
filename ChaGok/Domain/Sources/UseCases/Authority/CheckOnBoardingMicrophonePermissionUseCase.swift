import Core
import Foundation

/// 온보딩 과정에서 마이크 권한 확인을 위한 유즈케이스
public protocol CheckOnBoardingMicrophonePermissionUseCase: Sendable {
    /// 마이크 권한을 요청 또는 확인합니다. 온보딩 과정이므로 거부되어도 에러를 던지지 않고 상태를 반환합니다.
    /// - Returns: 최종 마이크 권한 상태
    /// - Throws: `CheckOnBoardingMicrophonePermissionUseCaseError.cancelled` 또는 `.unknown`
    func execute() async throws(CheckOnBoardingMicrophonePermissionUseCaseError) -> MicrophonePermissionStatus
}

/// 온보딩에서 마이크 권한을 요청 또는 확인 합니다.
public struct DefaultCheckOnBoardingMicrophonePermissionUseCase: CheckOnBoardingMicrophonePermissionUseCase {
    private let repository: VoiceRecordPermissionRepository

    public init(repository: VoiceRecordPermissionRepository) {
        self.repository = repository
    }

    public func execute() async throws(CheckOnBoardingMicrophonePermissionUseCaseError) -> MicrophonePermissionStatus {
        typealias UseCaseError = CheckOnBoardingMicrophonePermissionUseCaseError
        if Task.isCancelled { throw UseCaseError.cancelled }

        do {
            try await repository.checkRecordingPermission()
            return .authorized
        } catch {
            AppLogger.error(error)
            switch error {
                case .permissionDenied: return .denied // 권한 없음을 denied
                default: throw UseCaseError(error)
            }
        }
    }
}
