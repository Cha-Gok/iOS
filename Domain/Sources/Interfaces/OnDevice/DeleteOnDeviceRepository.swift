import Foundation

/// 온디바이스 모델 제거를 책임지는 `Repository`
public protocol DeleteOnDeviceRepository: Sendable {
    /// Whisper 모델을 제거합니다.
    func whisperModel() async throws(DeleteOnDeviceRepositoryError)

    /// MLX 모델을 제거합니다
    func mlxModel() async throws(DeleteOnDeviceRepositoryError)
}
