import Foundation

/// 온보딩 과정에서 마이크 권한 확인을 위한 유즈케이스
public protocol CheckMicrophonePermissionUseCase: Sendable {
    func execute() async throws
}

/// 온보딩에서 마이크 권한을 요청 또는 확인 합니다.
public struct DefaultCheckMicrophonePermissionUseCase: CheckMicrophonePermissionUseCase {
    private let repository: VoiceRecordRepository

    public init(repository: VoiceRecordRepository) {
        self.repository = repository
    }

    public func execute() async throws {
        try await repository.checkRecordingPermission()
    }
}
