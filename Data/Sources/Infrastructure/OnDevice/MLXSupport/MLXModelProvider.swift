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
            let path = try await resolve(
                configuration: configuration,
                from: #hubDownloader(),
                useLatest: false,
                progressHandler: progressHandler
            )
            
            // 다운로드 완료 복귀 직후 태스크 취소 상태 감지 (레이스 컨디션 봉쇄)
            if Task.isCancelled {
                AppLogger.info("MLX 다운로드 완료 복귀 후 취소 상태 감지 - 즉각 강제 소거 및 에러 방출")
                try? storageService.delete(fileURL: path.modelDirectory)
                throw CancellationError()
            }
            
            container = path
        } catch is CancellationError {
            throw .cancelled
        } catch let error as MLXModelDataSourceError {
            AppLogger.error(error)
            throw error
        } catch {
            if error is CancellationError ||
               (error as? URLError)?.code == .cancelled ||
               (error as NSError).domain == NSURLErrorDomain && (error as NSError).code == NSURLErrorCancelled {
                throw .cancelled
            }
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

            if storageService.exists(relativePath: relativePath) {
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
            if error is CancellationError ||
               (error as? URLError)?.code == .cancelled ||
               (error as NSError).domain == NSURLErrorDomain && (error as NSError).code == NSURLErrorCancelled {
                throw .cancelled
            }
            AppLogger.error(error)
            throw .unknown(error)
        }
    }

    public func delete() async throws(MLXModelDataSourceError) {
        defer {
            clear()
        }
        do {
            // 캐시된 경로가 있거나 디스크 감지가 되는 경우 해당 경로를 사용
            let downloadURL: URL
            if let path = try? await getDownloadPath() {
                downloadURL = path
            } else {
                // 다운로드 중 취소된 경우 등의 대비를 위해 기본 경로 계산
                let model = ChaGokModelSupport.current.model
                let configuration = try matchModelConfiguration(model: model)
                let repoID = configuration.id
                let relativePath = "huggingface/models/\(repoID)"
                downloadURL = storageService.absoluteURL(for: relativePath)
            }
            
            do {
                try storageService.delete(fileURL: downloadURL)
            } catch {
                guard case .fileNotFound = error else {
                    throw error
                }
            }
            AppLogger.info("MLX 모델/임시 폴더 삭제 완료: \(downloadURL.path)")
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
