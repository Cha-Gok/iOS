import Core
import Foundation

/// 마이크 권한 확인/요청 통합 유스케이스 프로토콜.
public protocol MicrophonePermissionUseCase: Sendable {
    /// 마이크 권한 상태를 확인합니다.
    /// - Returns: 현재 권한 상태
    /// - Throws: `MicrophonePermissionUseCaseError`
    func checkPermission() async throws(MicrophonePermissionUseCaseError) -> PermissionStatus

    /// 마이크 권한을 요청합니다.
    /// - Returns: 요청 결과 권한 상태
    /// - Throws: `MicrophonePermissionUseCaseError`
    func requestPermission() async throws(MicrophonePermissionUseCaseError) -> PermissionStatus
}

public struct DefaultMicrophonePermissionUseCase: MicrophonePermissionUseCase {
    private let repository: VoiceRecordRepository

    public init(repository: VoiceRecordRepository) {
        self.repository = repository
    }

    public func checkPermission() async throws(MicrophonePermissionUseCaseError) -> PermissionStatus {
        if Task.isCancelled { throw .cancelled }

        do {
            return try await repository.checkMicrophonePermission()
        } catch {
            AppLogger.error(error)
            throw MicrophonePermissionUseCaseError(error)
        }
    }

    public func requestPermission() async throws(MicrophonePermissionUseCaseError) -> PermissionStatus {
        if Task.isCancelled { throw .cancelled }

        do {
            return try await repository.requestMicrophonePermission()
        } catch {
            AppLogger.error(error)
            throw MicrophonePermissionUseCaseError(error)
        }
    }
}
