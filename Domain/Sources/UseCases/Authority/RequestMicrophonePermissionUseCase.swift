import Core
import Foundation

/// 마이크 권한 요청을 위한 유스케이스
public protocol RequestMicrophonePermissionUseCase: Sendable {
    /// 마이크 권한을 요청합니다.
    /// - Returns: 요청 결과 권한 상태. 이미 거부된 경우 `.denied`를 반환합니다.
    /// - Throws: `RequestMicrophonePermissionUseCaseError`
    func execute() async throws(RequestMicrophonePermissionUseCaseError) -> PermissionStatus
}

/// 마이크 권한을 요청합니다.
public struct DefaultRequestMicrophonePermissionUseCase: RequestMicrophonePermissionUseCase {
    private let repository: VoiceRecordRepository

    public init(repository: VoiceRecordRepository) {
        self.repository = repository
    }

    public func execute() async throws(RequestMicrophonePermissionUseCaseError) -> PermissionStatus {
        if Task.isCancelled { throw .cancelled }

        do {
            return try await repository.requestMicrophonePermission()
        } catch {
            AppLogger.error(error)
            throw RequestMicrophonePermissionUseCaseError(error)
        }
    }
}
