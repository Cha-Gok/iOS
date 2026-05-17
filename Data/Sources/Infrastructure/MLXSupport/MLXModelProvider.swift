import Foundation
import MLXLLM
import MLXLMCommon
import HuggingFace
import MLXHuggingFace
import Tokenizers

/// 데이터 레이어 내부에서 MLX 모델 컨테이너를 공유하고 생명주기를 관리하는 프로바이더.
@MainActor
public final class MLXModelProvider {
    /// 메모리에 로드된 모델 컨테이너. 로드되지 않았을 경우 nil입니다.
    public internal(set) var container: ModelContainer?
    
    public init() {}
    
    /// 모델 로드 여부 확인
    public var isLoaded: Bool {
        container != nil
    }
    
    /// 지정된 설정을 사용하여 모델을 메모리에 로드합니다.
    /// - Parameter configuration: 로드할 모델의 설정 정보
    public func loadModel(configuration: ModelConfiguration) async throws {
         if isLoaded { return }
        
        self.container = try await LLMModelFactory.shared.loadContainer(
            from: #hubDownloader(),
            using: #huggingFaceTokenizerLoader(),
            configuration: configuration
        )
    }
    
    /// 메모리에서 모델을 해제합니다.
    public func clear() {
        container = nil
    }
}
