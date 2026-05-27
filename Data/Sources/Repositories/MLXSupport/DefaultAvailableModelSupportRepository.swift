import Core
import Domain
import Foundation
import HuggingFace
import MLXHuggingFace
import MLXLLM
import MLXLMCommon

/// 온디바이스 AI 모델의 지원 여부 확인 및 다운로드를 담당하는 리포지토리 구현체.
public final class DefaultAvailableModelSupportRepository: AvailableModelSupportRepository {
    private let mlxProvider: any MLXModelDataSource
    private let whisperProvider: any WhisperDataSource

    public init(
        mlxProvider: any MLXModelDataSource,
        whisperProvider: any WhisperDataSource
    ) {
        self.mlxProvider = mlxProvider
        self.whisperProvider = whisperProvider
    }

    /// 현재 기기의 사양을 확인하여 지원 가능한 모델 정보를 반환합니다.
    public func checkMLXSupportModel() async -> ChaGokModelSupport {
        return ChaGokModelSupport.current
    }

    /// 현재 사용자의 On-Device LLM 모두  fetch 합니다.
    public func fetchSupportModels() async -> [ChaGokModelState] {
        let models: [ChaGokModel] = ChaGokModel.models
        let whisperStatus: Bool = await whisperProvider.isModelDownloaded()
        let mlxStatus: Bool = await mlxProvider.isDownloaded
        // gemma를 설치 할 수 있는지 여부
        let available: Bool = await checkMLXSupportModel().model == .gemma4_e2b_4bit
        return models.compactMap { model in
            switch model {
            case .whisper:
                return ChaGokModelState(
                    title: "Whisper",
                    subTitle: "기기에서 음성을 텍스트로 변환하기 위한\n필수 모델입니다.",
                    model: .whisper,
                    isDownloaded: whisperStatus ? .downloaded : .notDownloaded
                )
            case .gemma4_e2b_4bit:
                if available {
                    return ChaGokModelState(
                        title: "Gemma-4",
                        subTitle: "Ai 요약, 문법 교정을 통해 정확한 문장을 생성합니다.",
                        model: .gemma4_e2b_4bit,
                        isDownloaded: mlxStatus ? .downloaded : .notDownloaded
                    )
                }
                return nil
            default:
                return nil
            }
        }
    }
}
