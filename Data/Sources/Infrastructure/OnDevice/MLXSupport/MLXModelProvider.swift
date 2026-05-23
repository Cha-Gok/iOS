import Foundation
import HuggingFace
import MLX
import MLXHuggingFace
import MLXLLM
import MLXLMCommon
import Tokenizers

/// 데이터 레이어 내부에서 MLX 모델 컨테이너를 공유하고 생명주기를 관리하는 프로바이더.
public actor MLXModelProvider: MLXModelDataSource {
    /// 메모리에 로드된 모델 컨테이너. 로드되지 않았을 경우 nil입니다.
    public internal(set) var container: ModelContainer?
    private let fileManager: any StorageService

    public init(
        fileManager: any StorageService
    ) {
        self.fileManager = fileManager
    }

    /// 모델 로드 여부 확인
    public var isLoaded: Bool = false

    /// 모델 다운로드 여부 확인
    public var isDownloaded: Bool = false

    /// 지정된 설정을 사용하여 모델을 메모리에 로드합니다.
    /// - Parameter configuration: 로드할 모델의 설정 정보
    public func loadModel(configuration: ModelConfiguration) async throws {
        // 이미 로드된 경우 재로딩하지 않음
        if isLoaded { return }

        container = try await LLMModelFactory.shared.loadContainer(
            from: #hubDownloader(),
            using: #huggingFaceTokenizerLoader(),
            configuration: configuration
        )
        isLoaded = true
        isDownloaded = true
    }

    /// 메모리에서 모델을 해제합니다.
    public func clear() {
        MLX.Memory.cacheLimit = 0
        container = nil
        isLoaded = false
    }

    /// 허깅페이스 캐시 폴더를 삭제하여 모델을 기기에서 제거합니다.
    public func deleteModel() async throws {
        guard let container else { return }
        let downloadURL: URL = try await container.modelDirectory
        // file remove
        try fileManager.delete(fileURL: downloadURL)
        // deinit
        clear()
        isDownloaded = false
    }
}
