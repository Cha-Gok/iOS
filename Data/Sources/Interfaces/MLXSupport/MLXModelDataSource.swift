import Foundation
import HuggingFace
import MLXHuggingFace
import MLXLLM
import MLXLMCommon
import Tokenizers

/// MLX 모델 컨테이너를 공유하고 생명주기를 관리하는 데이터 소스 인터페이스.
public protocol MLXModelDataSource: Sendable {
    /// 다운로드
    func download(
        progressHandler: @Sendable @escaping (Progress) -> Void
    ) async throws(MLXModelDataSourceError)

    /// 메모리에서 모델을 해제하여 리소스를 반환합니다.
    func clear() async

    /// 메모리의 캐시(KVCache 등)만 해제하고 모델 컨테이너는 유지합니다.
    func clearCache() async

    /// 다운로드 경로를 전달합니다
    func getDownloadPath() async throws(MLXModelDataSourceError) -> URL

    /// 다운로드된 모델을 메모리에 로드합니다.
    func loadModel() async throws(MLXModelDataSourceError) -> ModelContext

    /// 모델을 제거합니다.
    func delete() async throws(MLXModelDataSourceError)
}
