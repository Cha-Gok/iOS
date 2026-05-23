import Domain

/// 온디바이스 모델 제거를 책임지는 `Repository`
public protocol DeleteOnDeviceRepository: Sendable {
    /// Whisper 모델을 제거합니다.
    func deleteWhisperModel() async throws(DeleteOnDeviceRepositoryError)

    /// MLX 모델을 제거합니다
    func deleteMLXModel() async throws(DeleteOnDeviceRepositoryError)
}
