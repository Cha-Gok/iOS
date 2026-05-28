import Core
import Domain
import Foundation
import HuggingFace
import MLX
import MLXHuggingFace
import MLXLLM
import MLXLMCommon
import Tokenizers

/// 데이터 레이어 내부에서 MLX 모델 컨테이너를 공유하고 생명주기를 관리하는 프로바이더.
public actor MLXModelProvider: MLXModelDataSource {
    private let storageService: any StorageService

    public init(storageService: any StorageService) {
        self.storageService = storageService
    }

    /// 메모리에 로드된 모델 컨테이너. 로드되지 않았을 경우 nil입니다.
    private var container: ResolvedModelConfiguration?

    public func download(
        progressHandler: @Sendable @escaping (Progress) -> Void
    ) async throws(MLXModelDataSourceError) {
        do {
            let model: ChaGokModel = ChaGokModelSupport.current.model
            let configuration = try matchModelConfiguration(model: model)
            container = try await resolve(
                configuration: configuration,
                from: #hubDownloader(),
                useLatest: false,
                progressHandler: progressHandler
            )
        } catch is CancellationError {
            throw .cancelled
        } catch let error as MLXModelDataSourceError {
            AppLogger.error(error)
            throw error
        } catch {
            AppLogger.error(error.localizedDescription)
            throw .unknown(error)
        }
    }

    /// 메모리에서 모델을 해제합니다.
    public func clear() {
        MLX.Memory.cacheLimit = 0
        container = nil
    }

    /// 모델이 설치된 경로를  전달 하기 위한 함수
    public func getDownloadPath() async throws(MLXModelDataSourceError) -> URL {
        if let path: URL = container?.modelDirectory {
            AppLogger.info("MLX 저장 위치 (캐시) : \(path)")
            return path
        }

        // 앱 재시작 시 메모리 초기화에 대응하기 위해 디스크의 물리적인 경로 체크
        do {
            let model: ChaGokModel = ChaGokModelSupport.current.model
            let configuration = try matchModelConfiguration(model: model)
            let repoID = configuration.id
            let relativePath = "huggingface/models/\(repoID)"
            let defaultPath = storageService.absoluteURL(for: relativePath)

            let relativeConfigJSON = "\(relativePath)/config.json"
            if storageService.exists(relativePath: relativeConfigJSON) {
                AppLogger.info("MLX 저장 위치 (디스크 감지) : \(defaultPath)")
                return defaultPath
            }
        } catch {
            throw .notFound
        }

        throw .notFound
    }

    public nonisolated func loadModel() async throws(MLXModelDataSourceError) -> ModelContext {
        do {
            let from: URL = try await getDownloadPath()
            let context = try await LLMModelFactory.shared.load(from: from, using: #huggingFaceTokenizerLoader())
            AppLogger.info("MLX model loaded: \(context)")
            return context
        } catch is CancellationError {
            throw .cancelled
        } catch let error as MLXModelDataSourceError {
            AppLogger.error(error)
            throw error
        } catch {
            AppLogger.error(error)
            throw .unknown(error)
        }
    }

    public func delete() async throws(MLXModelDataSourceError) {
        do {
            let downloadURL = try await getDownloadPath()
            try storageService.delete(fileURL: downloadURL)
            clear()
            AppLogger.info(downloadURL.absoluteString)
        } catch is CancellationError {
            throw .cancelled
        } catch let error as MLXModelDataSourceError {
            throw error
        } catch {
            throw .unknown(error)
        }
    }
}

// MARK: - Private

extension MLXModelProvider {
    /// Domain 객체를 통해  mlx-swift-lm의 LLMRegistry를 변환 합니다.
    private func matchModelConfiguration(model: ChaGokModel) throws(AvailableModelSupportRepositoryError)
        -> ModelConfiguration
    {
        switch model {
        case .gemma4_e2b_4bit:
            return LLMRegistry.gemma4_e2b_it_4bit
        case .none, .whisper:
            throw .notFoundModel
        }
    }
}
