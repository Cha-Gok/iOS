import Core
import Domain
import Foundation

/// 음성 인식(STT) 리포지토리 기본 구현체.
public struct DefaultSTTRepository: STTRepository, STTPermissionRepository {
    private let service: any STTService

    public init(service: any STTService) {
        self.service = service
    }

    public func transcribe(audioFileURL: URL) async throws(STTRepositoryError) -> Transcript {
        if Task.isCancelled { throw .cancelled }
        do {
            let text = try await service.transcribe(audioFileURL: audioFileURL)
            return Transcript(text: text)
        } catch {
            AppLogger.error(error)
            throw STTRepositoryError(error)
        }
    }

    public func checkSTTPermission() async throws(STTPermissionRepositoryError) -> PermissionStatus {
        if Task.isCancelled { throw .cancelled }
        return await service.checkPermission()
    }

    public func requestSTTPermission() async throws(STTPermissionRepositoryError) -> PermissionStatus {
        if Task.isCancelled { throw .cancelled }
        return await service.requestPermission()
    }
}
