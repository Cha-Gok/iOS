import Core
import Domain
import Foundation

public final class DefaultMlxOnDeviceRepository: OnDeviceRepository {
    private let provider: any MLXModelDataSource

    public init(
        provider: any MLXModelDataSource
    ) {
        self.provider = provider
    }

    public func download(progressHandler: @Sendable @escaping (Double) -> Void) async throws(OnDeviceRepositoryError) {
        do {
            try await provider.download { progress in
                progressHandler(progress.fractionCompleted)
            }
        } catch {
            AppLogger.error(error.localizedDescription)
            _ = try? await provider.delete()
            throw mapError(error)
        }
    }

    private func mapError(_ error: Error) -> OnDeviceRepositoryError {
        if let mlxError = error as? MLXModelDataSourceError {
            switch mlxError {
            case .cancelled:
                return .cancelled
            case .networkFailed:
                return .networkFailed
            default:
                return .unknown(mlxError)
            }
        }
        return OnDeviceRepositoryError.mapDownloadError(error)
    }

    /// 다운로드 경로에 존재하는 모델 경로를 삭제합니다.
    public func delete() async throws(DeleteOnDeviceRepositoryError) -> OnDeviceStatus {
        do {
            try await provider.delete()
            return OnDeviceStatus(storage: .notDownloaded)
        } catch {
            AppLogger.error(error)
            switch error {
            case .cancelled:
                throw .cancelled
            case .notFound, .downloadFailed, .deleteFailed:
                return OnDeviceStatus(storage: .notDownloaded)
            case .networkFailed:
                throw .deleteMLXFailed
            case .unknown(let underlying):
                if underlying is CancellationError ||
                    (underlying as? URLError)?.code == .cancelled ||
                    (underlying as NSError).domain == NSURLErrorDomain && (underlying as NSError)
                    .code == NSURLErrorCancelled
                {
                    throw .cancelled
                }
                throw .unknown(underlying)
            }
        }
    }

    public func checkStatus() async -> OnDeviceStatus {
        do {
            _ = try await provider.getDownloadPath()
            return OnDeviceStatus(storage: .downloaded)
        } catch {
            return OnDeviceStatus(storage: .notDownloaded)
        }
    }
}
