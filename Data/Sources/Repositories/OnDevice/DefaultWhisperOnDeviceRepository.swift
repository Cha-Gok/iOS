import Core
import Domain
import Foundation

/// Whisper 객체에 대한 기능 구현체를 담은 `Repository`
public struct DefaultWhisperOnDeviceRepository: OnDeviceRepository {
    let provider: any WhisperDataSource

    public init(
        provider: any WhisperDataSource
    ) {
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
                    AppLogger.info(OnDeviceRepositoryError.cancelled.errorDescription)
                    continuation.finish(throwing: OnDeviceRepositoryError.cancelled)
                } catch let error as WhisperDataSourceError {
                    let repoError: OnDeviceRepositoryError
                    switch error {
                    case .cancelled:
                        repoError = .cancelled
                    case .networkFailed, .notRecommendedModel:
                        repoError = .networkFailed
                    case .notFound:
                        repoError = .unknown(error)
                    case .loadFailed:
                        repoError = .loadFailed
                    case .unknown(let underlying):
                        repoError = .unknown(underlying)
                    }
                    AppLogger.info(repoError.errorDescription)
                    continuation.finish(throwing: repoError)
                } catch {
                    AppLogger.error(error.localizedDescription)
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
            try await provider.delete()
            return OnDeviceStatus(storage: .notDownloaded, runtime: .unloaded)
        } catch {
            AppLogger.error(error)
            throw .deleteWhisperFailed
        }
    }
}
