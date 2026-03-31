import Core
import Domain
import Speech

/// Speech 프레임워크 기반 음성 서비스
public actor SpeechService: STTService {
    private enum SpeechRecognitionError {
        static let frameworkDomain = "com.apple.speech.speechrecognitionframework"
        static let assistantDomain = "kAFAssistantErrorDomain"
        static let cancelledCode = 301
        static let noRecognitionResultCode = 203
    }

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
        guard !Task.isCancelled else { throw .cancelled }
        guard currentTask == nil else { throw .alreadyTranscribing }

        AppLogger.info("음성 전사를 시작합니다: \(audioFileURL.lastPathComponent)")

        do {
            return try await withTaskCancellationHandler {
                try await withCheckedThrowingContinuation { continuation in
                    do {
                        try self.startRecognitionTask(
                            audioFileURL: audioFileURL,
                            continuation: continuation
                        )
                    } catch let error as STTServiceError {
                        continuation.resume(throwing: error)
                    } catch {
                        continuation.resume(throwing: self.sttServiceError(from: error))
                    }
                }
            } onCancel: {
                Task { await self.cancelCurrentTask() }
            }
        } catch let error as STTServiceError {
            throw error
        } catch {
            throw sttServiceError(from: error)
        }
    }

    // MARK: - Private

    private func startRecognitionTask(
        audioFileURL: URL,
        continuation: CheckedContinuation<String, any Error>
    ) throws(STTServiceError) {
        guard !Task.isCancelled else { throw .cancelled }
        guard let recognizer = SFSpeechRecognizer(), recognizer.isAvailable else {
            throw .recognizerUnavailable
        }

        let request = SFSpeechURLRecognitionRequest(url: audioFileURL)

        currentContinuation = continuation
        currentTask = makeRecognitionTask(recognizer: recognizer, request: request)
    }

    private func makeRecognitionTask(
        recognizer: SFSpeechRecognizer,
        request: SFSpeechURLRecognitionRequest
    ) -> SFSpeechRecognitionTask {
        recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }

            if let error {
                Task { await self.failTask(self.sttServiceError(from: error)) }
                return
            }

            guard let result, result.isFinal else { return }

            let text = result.bestTranscription.formattedString
            AppLogger.info("음성 전사가 완료되었습니다. 글자 수: \(text.count)")
            Task { await self.finishTask(text) }
        }
    }

    private func sttServiceError(from error: Error) -> STTServiceError {
        let nsError = error as NSError

        switch (nsError.domain, nsError.code) {
        case (SpeechRecognitionError.frameworkDomain, SpeechRecognitionError.cancelledCode):
            return .cancelled
        case (SpeechRecognitionError.assistantDomain, SpeechRecognitionError.noRecognitionResultCode):
            return .transcribeFailed
        default:
            return .unknown(error)
        }
    }

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
        AppLogger.info("음성 전사가 취소되었습니다.")
        continuation?.resume(throwing: STTServiceError.cancelled)
    }
}
