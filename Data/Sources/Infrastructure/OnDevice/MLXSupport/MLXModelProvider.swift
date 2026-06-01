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
//        #if DEBUG
//            // ⚠️ 디버깅용 시뮬레이션: 에러 상황별 핸들링을 안전하게 테스트하기 위한 디버그 스위치입니다.
//            try? await Task.sleep(nanoseconds: 2 * 1_000_000_000)
//
//            // [옵션 1] 네트워크 오류 시뮬레이션 (networkFailed)
//            // -> 활성화 시 "네트워크 연결이 유실되었습니다" 문구가 노출됩니다.
//            // throw URLError(.notConnectedToInternet)
//
//            // [옵션 2] 알 수 없는 시스템 오류 시뮬레이션 (unknown)
//            // -> 활성화 시 "다운로드에 실패했습니다" 문구와 상세 에러 문구가 노출됩니다.
//            throw .unknown(NSError(
//                domain: "SimulatedErrorDomain",
//                code: 999,
//                userInfo: [NSLocalizedDescriptionKey: "알 수 없는 기기 내부 디스크 쓰기 오류가 발생했습니다. (Simulated)"]
//            ))
//        #endif
        do {
            let model: ChaGokModel = ChaGokModelSupport.current.model
            let configuration = try matchModelConfiguration(model: model)
            let path = try await resolve(
                configuration: configuration,
                from: #hubDownloader(),
                useLatest: false,
                progressHandler: progressHandler
            )
            container = path
        } catch {
            if error is CancellationError ||
                (error as? URLError)?.code == .cancelled ||
                (error as NSError).domain == NSURLErrorDomain && (error as NSError).code == NSURLErrorCancelled
            {
                throw .cancelled
            }
            AppLogger.error(error)
            throw .downloadFailed
        }
    }

    /// 메모리에서 모델을 해제합니다.
    public func clear() {
        if container != nil {
            MLX.Memory.cacheLimit = 0
            container = nil
        }
    }

    /// 모델이 설치된 경로를  전달 하기 위한 함수
    public func getDownloadPath() async throws(MLXModelDataSourceError) -> URL {
        if let path: URL = container?.modelDirectory {
            AppLogger.info("MLX 저장 위치 (캐시) : \(path)")
            return path
        }

        // 앱 재시작 시 메모리 초기화에 대응하기 위해 디스크의 물리적인 경로 체크
        let model = ChaGokModelSupport.current.model
        do {
            let configuration = try matchModelConfiguration(model: model)

            // 1. 디렉토리 모델 처리
            if case .directory(let url) = configuration.id {
                let modelURL = url.scheme == nil ? storageService.absoluteURL(for: url.path) : url
                if FileManager.default.fileExists(atPath: modelURL.path) {
                    return modelURL
                }
            }

            // 2. 허브 모델(.id) 처리
            if case .id(let name, _) = configuration.id {
                let cachesURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
                let repoFolderName = "models--" + name.replacingOccurrences(of: "/", with: "--")
                let snapshotsURL = cachesURL.appendingPathComponent("huggingface/hub/\(repoFolderName)/snapshots")

                if let firstSnapshot = try? FileManager.default.contentsOfDirectory(
                    at: snapshotsURL,
                    includingPropertiesForKeys: nil
                ).first {
                    // 완결성 검사: 모델 폴더 내부에 핵심 설정인 config.json 및 tokenizer 파일들이 완벽하게 다운로드되어 존재하는지 검사하여 C++ 크래시를 예방합니다.
                    let configURL = firstSnapshot.appendingPathComponent("config.json")
                    let tokenizerURL = firstSnapshot.appendingPathComponent("tokenizer.json")
                    let tokenizerConfigURL = firstSnapshot.appendingPathComponent("tokenizer_config.json")

                    if FileManager.default.fileExists(atPath: configURL.path),
                       FileManager.default.fileExists(atPath: tokenizerURL.path),
                       FileManager.default.fileExists(atPath: tokenizerConfigURL.path)
                    {
                        return firstSnapshot
                    }
                }
            }

            throw MLXModelDataSourceError.notFound
        } catch {
            throw .notFound
        }
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
                (error as NSError).domain == NSURLErrorDomain && (error as NSError).code == NSURLErrorCancelled
            {
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
            let model = ChaGokModelSupport.current.model
            let configuration = try matchModelConfiguration(model: model)

            // 1. container가 존재하는 경우 바로 지우기
            if let resolvedDirectory = container?.modelDirectory {
                let deleteURL: URL = switch configuration.id {
                case .directory:
                    resolvedDirectory
                case .id:
                    resolvedDirectory.deletingLastPathComponent().deletingLastPathComponent()
                }

                if FileManager.default.fileExists(atPath: deleteURL.path) {
                    do {
                        try storageService.delete(fileURL: deleteURL)
                    } catch {
                        AppLogger.error("MLX 모델 삭제 경로 오류 : \(deleteURL)")
                    }
                }
                AppLogger.info("MLX 모델 삭제 완료 (container 기반): \(deleteURL.path)")
                return
            }

            // 2. container가 없는 경우 디스크 물리 경로를 찾아서 지우기
            let deleteURL: URL
            switch configuration.id {
            case .directory(let url):
                deleteURL = url.scheme == nil ? storageService.absoluteURL(for: url.path) : url
            case .id(let name, _):
                let cachesURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
                let repoFolderName = "models--" + name.replacingOccurrences(of: "/", with: "--")
                deleteURL = cachesURL.appendingPathComponent("huggingface/hub/\(repoFolderName)")
            }

            if FileManager.default.fileExists(atPath: deleteURL.path) {
                do {
                    try storageService.delete(fileURL: deleteURL)
                } catch {
                    AppLogger.info("MLX 모델 삭제 실패 (물리 경로 기반): \(deleteURL.path)")
                }
            }
            AppLogger.info("MLX 모델 삭제 완료 (물리 경로 기반): \(deleteURL.path)")
        } catch {
            AppLogger.error(error)
            throw MLXModelDataSourceError.deleteFailed
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
