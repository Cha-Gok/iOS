import Core
import Domain
import Foundation

public final class DefaultMlxOnDeviceRepository: OnDeviceRepository {
    private let provider: any MLXModelDataSource
    private let storageService: any StorageService

    public init(
        provider: any MLXModelDataSource,
        storageService: any StorageService
    ) {
        self.provider = provider
        self.storageService = storageService
    }

    public func download() -> AsyncThrowingStream<OnDeviceStatus, any Error> {
        AsyncThrowingStream(
            OnDeviceStatus.self,
            bufferingPolicy: .unbounded
        ) { continuation in
            let task = Task {
                do {
                    continuation.yield(OnDeviceStatus(storage: .downloading(progress: 0), runtime: .unloaded))
                    // 모델 파일만 다운로드 ( resolve )
                    try await provider.download { progress in
                        continuation.yield(
                            OnDeviceStatus(
                                storage: .downloading(progress: progress.fractionCompleted),
                                runtime: .unloaded
                            )
                        )
                    }
                    continuation.yield(OnDeviceStatus(storage: .downloaded, runtime: .unloaded))
                    continuation.finish()
                } catch is CancellationError {
                    AppLogger.info(OnDeviceRepositoryError.cancelled.errorDescription)
                    continuation.finish(throwing: OnDeviceRepositoryError.cancelled)
                } catch let error as MLXModelDataSourceError {
                    let repoError: OnDeviceRepositoryError
                    switch error {
                    case .cancelled:
                        repoError = .cancelled
                    case .networkFailed:
                        repoError = .networkFailed
                    case .notFound:
                        repoError = .unknown(error)
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

    /// 다운로드 경로에 존재하는 모델 경로를 삭제합니다.
    public func delete() async throws(DeleteOnDeviceRepositoryError) -> OnDeviceStatus {
        do {
            let downloadURL: URL = try await provider.getDownloadPath()
            // file remove
            try storageService.delete(fileURL: downloadURL)
            // deinit
            await provider.clear()
            return OnDeviceStatus(storage: .notDownloaded, runtime: .unloaded)
        } catch is CancellationError {
            throw .cancelled
        } catch let error as MLXModelDataSourceError {
            AppLogger.error(error)
            switch error {
            case .cancelled:
                throw .cancelled
            case .notFound:
                // 이미 존재하지 않아 삭제할 대상이 없는 경우 성공으로 간주하여 상태를 정상 복구합니다.
                await provider.clear()
                return OnDeviceStatus(storage: .notDownloaded, runtime: .unloaded)
            case .networkFailed:
                throw .deleteMLXFailed
            case .unknown(let underlying):
                if underlying is CancellationError {
                    throw .cancelled
                }
                throw .unknown(underlying)
            }
        } catch {
            AppLogger.error(error)
            throw .deleteMLXFailed
        }
    }
}
