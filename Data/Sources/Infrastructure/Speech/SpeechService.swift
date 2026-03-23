import Domain
import Speech

/// Speech 프레임워크 기반 음성 서비스
public actor SpeechService: STTPermissionService, STTService {
    /// 진행 중인 전사 작업
    private var currentTask: SFSpeechRecognitionTask?
    /// onCancel에서 접근하기 위해 actor 프로퍼티로 보관
    private var currentContinuation: CheckedContinuation<String, any Error>?

    public init() {}

    // MARK: - STTPermissionService

    public func checkPermission() async -> PermissionStatus {
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized:
            return .authorized
        case .denied, .restricted:
            return .denied
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .denied
        }
    }

    public func requestPermission() async -> PermissionStatus {
        let status = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }

        switch status {
        case .authorized:
            return .authorized
        case .denied, .restricted:
            return .denied
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .denied
        }
    }

    // MARK: - STTService

    public func transcribe(audioFileURL: URL) async throws(STTServiceError) -> String {
        guard currentTask == nil else { throw .alreadyTranscribing }

        guard let recognizer = SFSpeechRecognizer(), recognizer.isAvailable else {
            throw .recognizerUnavailable
        }

        let request = SFSpeechURLRecognitionRequest(url: audioFileURL)

        do {
            return try await withTaskCancellationHandler {
                // withCheckedThrowingContinuation body는 actor executor에서 동기 실행
                // (Swift 6: isolation: #isolation 상속) → actor 프로퍼티 직접 할당 안전
                try await withCheckedThrowingContinuation { continuation in
                    self.currentContinuation = continuation
                    let task = recognizer.recognitionTask(with: request) { [weak self] result, error in
                        guard let self else { return }
                        // 에러 우선 확인 (중복 resume 방지)
                        if let error {
                            Task { await self.failTask(STTServiceError(error)) }
                        } else if let result, result.isFinal {
                            // SFSpeechRecognitionResult는 Sendable 미준수
                            // → Task 클로저 캡처 전에 String 추출
                            let text = result.bestTranscription.formattedString
                            Task { await self.finishTask(text) }
                        }
                    }
                    self.currentTask = task
                }
            } onCancel: {
                // SFSpeechRecognitionTask.cancel() 이후 completion handler 호출 미보장
                // → currentContinuation actor 프로퍼티를 통해 직접 resume
                Task { await self.cancelCurrentTask() }
            }
        } catch let error as STTServiceError {
            throw error
        } catch {
            throw STTServiceError(error)
        }
    }

    // MARK: - Private

    private func finishTask(_ text: String) {
        let continuation = currentContinuation
        currentContinuation = nil
        currentTask = nil
        continuation?.resume(returning: text)
    }

    private func failTask(_ error: STTServiceError) {
        let continuation = currentContinuation
        currentContinuation = nil
        currentTask = nil
        continuation?.resume(throwing: error)
    }

    private func cancelCurrentTask() {
        let continuation = currentContinuation
        currentContinuation = nil
        currentTask?.cancel()
        currentTask = nil
        continuation?.resume(throwing: STTServiceError.cancelled)
    }
}
