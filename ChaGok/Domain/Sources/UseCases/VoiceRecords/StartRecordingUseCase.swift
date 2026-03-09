import Core
import Foundation

/// 녹음 시작 유스케이스 프로토콜.
/// 호출 시 마이크 권한을 확인하고, 허용된 경우 녹음을 시작한 뒤 파형(Waveform) 스트림을 반환합니다.
public protocol StartRecordingUseCase {
    /// 녹음을 시작하고 실시간 파형 데이터 스트림을 반환합니다.
    /// - Returns: 녹음 중 생성되는 파형 샘플 스트림. 호출부에서 `for await`로 소비하여 UI에 파형을 그릴 수 있습니다.
    /// - Throws: `StartRecordingUseCaseError` (권한 거부, 녹음 시작 실패)
    func execute() async throws(StartRecordingUseCaseError) -> AsyncStream<Waveform>
}

public struct DefaultStartRecordingUseCase: StartRecordingUseCase {

    private let permissionRepository: VoiceRecordPermissionRepository
    private let recordingRepository: VoiceRecordStartRepository

    public init(
        permissionRepository: VoiceRecordPermissionRepository,
        recordingRepository: VoiceRecordStartRepository
    ) {
        self.permissionRepository = permissionRepository
        self.recordingRepository = recordingRepository
    }

    public func execute() async throws(StartRecordingUseCaseError) -> AsyncStream<Waveform> {
        if Task.isCancelled {
            throw .cancelled
        }

        do {
            try await permissionRepository.checkRecordingPermission()

            if Task.isCancelled { throw StartRecordingUseCaseError.cancelled }

            return try await recordingRepository.startRecording()
        } catch {
            AppLogger.error(error)
            throw mapFromRepository(error)
        }
    }

    private func mapFromRepository(_ error: Error) -> StartRecordingUseCaseError {
        if let repositoryError = error as? VoiceRecordPermissionRepositoryError {
            switch repositoryError {
            case .permissionDenied: return .permissionDenied
            case .cancelled: return .cancelled
            case .unknown(let error): return .unknown(error)
            }
        } else if let repositoryError = error as? VoiceRecordStartRepositoryError {
            switch repositoryError {
            case .startFailed: return .startFailed
            case .cancelled: return .cancelled
            case .unknown(let error): return .unknown(error)
            }
        } else {
            return .unknown(error)
        }
    }
}
