import Core
import Domain
import Foundation

/// 음성 인식(STT) 리포지토리 기본 구현체.
public struct DefaultSTTRepository: STTRepository {
    private let service: any STTService
    private let storageService: any StorageService

    public init(service: any STTService, storageService: any StorageService) {
        self.service = service
        self.storageService = storageService
    }

    public func transcribe(audioFilePath: String) async throws(STTRepositoryError) -> Transcript {
        if Task.isCancelled { throw .cancelled }
        let absoluteURL = storageService.absoluteURL(for: audioFilePath)
        do {
            let result = try await service.transcribe(audioFileURL: absoluteURL)
            let segments = result.segments.map {
                TranscriptSegment(substring: $0.substring, timestamp: $0.timestamp, duration: $0.duration)
            }
            return Transcript(text: result.text, segments: segments)
        } catch {
            AppLogger.error(error)
            throw STTRepositoryError(error)
        }
    }

    public func checkSTTPermission() -> PermissionStatus {
        service.checkPermission()
    }

    public func requestSTTPermission() async throws(STTPermissionRepositoryError) -> PermissionStatus {
        if Task.isCancelled { throw .cancelled }
        return await service.requestPermission()
    }
}
