import Foundation
import MLXLLM
import MLXLMCommon

/// MLX 모델 컨테이너를 공유하고 생명주기를 관리하는 데이터 소스 인터페이스.
public protocol MLXModelDataSource: Sendable {
    /// 모델 로드 여부 확인
    var isLoaded: Bool { get async }

    /// 모델 다운로드 여부 확인
    var isDownloaded: Bool { get async }

    /// 다운로드
    func download(
        progressHandler: @Sendable @escaping (Progress) -> Void
    ) async throws(MLXModelDataSourceError)

    /// 메모리에서 모델을 해제하여 리소스를 반환합니다.
    func clear() async

    /// 다운로드 경로를 전달합니다
    func getDownloadPath() async throws(MLXModelDataSourceError) -> URL
}
