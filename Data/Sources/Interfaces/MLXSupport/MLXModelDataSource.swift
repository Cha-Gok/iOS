import Foundation
import MLXLLM
import MLXLMCommon

/// MLX 모델 컨테이너를 공유하고 생명주기를 관리하는 데이터 소스 인터페이스.
public protocol MLXModelDataSource: Sendable {
    /// 메모리에 로드된 모델 컨테이너. 로드되지 않았을 경우 nil입니다.
    var container: ModelContainer? { get async }

    /// 모델 로드 여부 확인
    var isLoaded: Bool { get async }

    /// 모델 다운로드 여부 확인
    var isDownloaded: Bool { get async }

    /// 지정된 설정을 사용하여 모델을 메모리에 로드합니다.
    /// - Parameter configuration: 로드할 모델의 설정 정보
    func loadModel(configuration: ModelConfiguration) async throws

    /// 메모리에서 모델을 해제하여 리소스를 반환합니다.
    func clear() async

    /// 다운로드된 로컬 모델 캐시 파일을 제거합니다.
    func deleteModel() async throws
}
