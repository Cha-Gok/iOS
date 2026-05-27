import Foundation

public protocol OnDeviceRepository: Sendable {
    /// 모델 파일을 다운로드하여 로컬 캐시에 저장합니다. (메모리 적재 X)
    func download() -> AsyncThrowingStream<OnDeviceStatus, any Error>
    /// 모델을 제거합니다.
    func delete() async throws(DeleteOnDeviceRepositoryError) -> OnDeviceStatus
}
