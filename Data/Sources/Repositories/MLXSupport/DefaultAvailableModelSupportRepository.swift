import Foundation
import Domain
import HuggingFace
import MLXHuggingFace
import MLXLLM
import MLXLMCommon
import Tokenizers

/// 온디바이스 AI 모델의 지원 여부 확인 및 다운로드를 담당하는 리포지토리 구현체.
@MainActor
public final class DefaultAvailableModelSupportRepository: AvailableModelSupportRepository {
    
    private let provider: MLXModelProvider
    
    public init(
        provider: MLXModelProvider
    ) {
        self.provider = provider
    }
    
    /// 모델이 현재 메모리에 로드되어 사용 가능한 상태인지 여부
    public var isModelLoaded: Bool {
        provider.isLoaded
    }
    
    /// 현재 기기의 사양을 확인하여 지원 가능한 모델 정보를 반환합니다.
    public func checkSupportModel() -> ChaGokModelSupport {
        let current = ChaGokModelSupport.current
        return current
    }
    
    /// 모델 다운로드 (resolve)
    /// 모델 파일만 로컬 캐시에 저장하며, 메모리에 적재하지는 않습니다.
    public func downloadModel(
        progressHandler: @Sendable @escaping (Progress) -> Void
    ) async throws(AvailableModelSupportRepositoryError) {
        do {
            let support = checkSupportModel()
            let modelConfiguration = try matchModelConfiguration(model: support.model)
            
            // 모델 파일만 다운로드 및 확인
            _ = try await resolve(
                configuration: modelConfiguration,
                from: #hubDownloader(),
                useLatest: false,
            ) { progress in
                progressHandler(progress)
            }
            
        } catch let error as AvailableModelSupportRepositoryError {
            throw error
        } catch is CancellationError {
            throw .cancelled
        } catch {
            throw .unknown(error)
        }
    }
    
    private func matchModelConfiguration(model: ChaGokModel) throws(AvailableModelSupportRepositoryError) -> ModelConfiguration {
        switch model {
        case .gemma4_e2b_4bit:
            return LLMRegistry.gemma4_e2b_it_4bit
        case .none:
            throw .notFoundModel
        }
    }
}
