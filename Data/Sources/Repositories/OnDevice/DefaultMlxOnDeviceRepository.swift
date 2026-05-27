import Core
import Domain
import Foundation
import HuggingFace
import MLX
import MLXHuggingFace
import MLXLLM
import MLXLMCommon
import Tokenizers

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

    /// 지정된 설정을 사용하여 모델을 메모리에 로드합니다.
    /// - Parameter configuration: 로드할 모델의 설정 정보
    public func loadModel() async throws(OnDeviceRepositoryError) {
        do {
            let from: URL = try await provider.getDownloadPath()
            let context = try await LLMModelFactory.shared.load(from: from, using: #huggingFaceTokenizerLoader())
            AppLogger.info("modelContext : \(context)")
        } catch let error as MLXModelDataSourceError {
            AppLogger.error(error)
            throw .unknown(error)
        } catch {
            AppLogger.error(error)
            throw .loadFailed
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
        } catch {
            AppLogger.error(error)
            throw .deleteMLXFailed
        }
    }
}
