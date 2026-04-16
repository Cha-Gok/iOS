import Core
import Foundation

/// 녹음 통합 유스케이스 프로토콜.
/// 녹음의 시작, 일시정지, 재개, 완료, 취소를 하나의 인터페이스로 제공합니다.
public protocol RecordingUseCase: Sendable {
    /// 녹음을 시작하고 실시간 파형 데이터 스트림을 반환합니다.
    /// - Returns: 녹음 중 생성되는 파형 샘플 스트림
    /// - Throws: `RecordingUseCaseError`
    func start() async throws(RecordingUseCaseError) -> AsyncStream<Waveform>

    /// 진행 중인 녹음을 일시 정지합니다.
    /// - Throws: `RecordingUseCaseError`
    func pause() async throws(RecordingUseCaseError)

    /// 일시 정지된 녹음을 다시 이어서 녹음합니다.
    /// - Throws: `RecordingUseCaseError`
    func resume() async throws(RecordingUseCaseError)

    /// 녹음을 종료하고 저장한 뒤, 저장된 녹음 정보를 반환합니다.
    /// - Returns: 저장된 녹음 엔티티
    /// - Throws: `RecordingUseCaseError`
    func finish() async throws(RecordingUseCaseError) -> VoiceRecord

    /// 진행 중인 녹음을 취소하고 임시 파일을 삭제합니다.
    /// - Throws: `RecordingUseCaseError`
    func cancel() async throws(RecordingUseCaseError)
}

public struct DefaultRecordingUseCase: RecordingUseCase {
    private let repository: VoiceRecordRepository

    public init(repository: VoiceRecordRepository) {
        self.repository = repository
    }

    public func start() async throws(RecordingUseCaseError) -> AsyncStream<Waveform> {
        if Task.isCancelled { throw .cancelled }

        do {
            return try await repository.startRecording()
        } catch {
            AppLogger.error(error)
            throw RecordingUseCaseError(error)
        }
    }

    public func pause() async throws(RecordingUseCaseError) {
        if Task.isCancelled { throw .cancelled }

        do {
            try await repository.pauseRecording()
        } catch {
            AppLogger.error(error)
            throw RecordingUseCaseError(error)
        }
    }

    public func resume() async throws(RecordingUseCaseError) {
        if Task.isCancelled { throw .cancelled }

        do {
            try await repository.resumeRecording()
        } catch {
            AppLogger.error(error)
            throw RecordingUseCaseError(error)
        }
    }

    public func finish() async throws(RecordingUseCaseError) -> VoiceRecord {
        if Task.isCancelled { throw .cancelled }

        do {
            return try await repository.finishRecording()
        } catch {
            AppLogger.error(error)
            throw RecordingUseCaseError(error)
        }
    }

    public func cancel() async throws(RecordingUseCaseError) {
        if Task.isCancelled { throw .cancelled }

        do {
            try await repository.cancelRecording()
        } catch {
            AppLogger.error(error)
            throw RecordingUseCaseError(error)
        }
    }
}
