import Foundation

public protocol OnDeviceRepository: Sendable {
    /// 모델 파일을 다운로드하여 로컬 캐시에 저장합니다. (메모리 적재 X)
    func download() -> AsyncThrowingStream<OnDeviceStatus, any Error>

    /// 지정된 설정을 사용하여 모델을 메모리에 로드합니다.
    /// - Parameter configuration: 로드할 모델의 설정 정보
    func loadModel() async throws(OnDeviceRepositoryError)

    /// 모델을 제거합니다.
    func delete() async throws(DeleteOnDeviceRepositoryError) -> OnDeviceStatus
}
