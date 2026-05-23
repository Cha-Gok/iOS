import Core
import Domain
import Foundation

public final class DefaultDeleteOnDeviceRepository: DeleteOnDeviceRepository {
    private let mlxProvider: any MLXModelDataSource
    private let whisperProvider: any WhisperDataSource

    public init(
        mlxProvider: any MLXModelDataSource,
        whisperProvider: any WhisperDataSource
    ) {
        self.mlxProvider = mlxProvider
        self.whisperProvider = whisperProvider
    }

    /// 다운로드 된 모델을 제거합니다. ( MLX Model )
    public func mlxModel() async throws(DeleteOnDeviceRepositoryError) {
        if Task.isCancelled { throw .cancelled }

        do {
            try await mlxProvider.deleteModel()
        } catch {
            AppLogger.error(error)
            throw .deleteMLXFailed
        }
    }

    /// 다운로드 된 모델을 제거합니다. ( Whisper Model )
    public func whisperModel() async throws(DeleteOnDeviceRepositoryError) {
        if Task.isCancelled { throw .cancelled }

        do {
            try await whisperProvider.deleteModel()
        } catch {
            AppLogger.error(error)
            throw .deleteWhisperFailed
        }
    }
}
