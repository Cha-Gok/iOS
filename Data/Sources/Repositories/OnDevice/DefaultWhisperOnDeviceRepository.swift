import Core
import Domain
import Foundation

/// Whisper 객체에 대한 기능 구현체를 담은 `Repository`
public struct DefaultWhisperOnDeviceRepository: OnDeviceRepository {
    private let storageService: any StorageService
    let provider: any WhisperDataSource

    public init(
        storageService: any StorageService,
        provider: any WhisperDataSource
    ) {
        self.storageService = storageService
        self.provider = provider
    }

    public func download() -> AsyncThrowingStream<OnDeviceStatus, any Error> {
        AsyncThrowingStream(
            OnDeviceStatus.self,
            bufferingPolicy: .unbounded
        ) { continuation in
            let task = Task {
                do {
                    continuation.yield(OnDeviceStatus(storage: .downloading(progress: 0), runtime: .unloaded))
                    try await provider.download { progress in
                        continuation.yield(OnDeviceStatus(
                            storage: .downloading(progress: progress.fractionCompleted),
                            runtime: .unloaded
                        ))
                    }
                    continuation.yield(OnDeviceStatus(storage: .downloaded, runtime: .unloaded))
                    continuation.finish()
                } catch is CancellationError {
                    continuation.finish(throwing: OnDeviceRepositoryError.cancelled)
                } catch {
                    continuation.finish(throwing: OnDeviceRepositoryError.mapDownloadError(error))
                }
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    public func delete() async throws(DeleteOnDeviceRepositoryError) -> OnDeviceStatus {
        do {
            let downloadURL: URL = try await provider.getDownloadPath()
            // file remove
            try storageService.delete(fileURL: downloadURL)
            // deinit
            await provider.clearCache()
            return OnDeviceStatus(storage: .notDownloaded, runtime: .unloaded)
        } catch {
            AppLogger.error(error)
            throw .deleteWhisperFailed
        }
    }
}
