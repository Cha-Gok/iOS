import Foundation

public protocol OnDeviceRepository: Sendable {
    /// 모델의 용량을 노출합니다.
    var modelSize: String { get async }
    /// 모델 파일을 다운로드하여 로컬 캐시에 저장합니다. (메모리 적재 X)
    func download(progressHandler: @Sendable @escaping (Double) -> Void) async throws(OnDeviceRepositoryError)
    /// 모델을 제거합니다.
    func delete() async throws(DeleteOnDeviceRepositoryError) -> OnDeviceStatus
    /// 현재 기기에 모델이 온전히 다운로드되어 존재하는지 실시간 디스크 상태를 체크합니다.
    func checkStatus() async -> OnDeviceStatus
}
