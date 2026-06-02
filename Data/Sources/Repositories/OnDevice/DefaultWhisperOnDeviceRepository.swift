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
        if let whisperError = error as? WhisperDataSourceError {
            switch whisperError {
            case .cancelled:
                return .cancelled
            case .networkFailed, .notRecommendedModel:
                return .networkFailed
            default:
                return .unknown(whisperError)
            }
        }
        return OnDeviceRepositoryError.mapDownloadError(error)
    }

    public func delete() async throws(DeleteOnDeviceRepositoryError) -> OnDeviceStatus {
        do {
            try await provider.delete()
            return OnDeviceStatus(storage: .notDownloaded)
        } catch {
            AppLogger.error(error)
            throw .deleteWhisperFailed
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
