import Core
import Domain
import Foundation
import Speech

/// 음성 인식(STT) 리포지토리 기본 구현체.
public actor DefaultSTTRepository: STTRepository {
    private let storageService: any StorageService
    private var currentTask: SFSpeechRecognitionTask?
    private var currentContinuation: CheckedContinuation<Transcript, any Error>?

    public init(storageService: any StorageService) {
        self.storageService = storageService
    }

    public func transcribe(audioFilePath: String) async throws(STTRepositoryError) -> Transcript {
        guard !Task.isCancelled else { throw .cancelled }
        guard currentTask == nil else { throw .transcribeFailed }

        let absoluteURL = storageService.absoluteURL(for: audioFilePath)
        AppLogger.info("음성 전사를 시작합니다: \(absoluteURL.lastPathComponent)")

        do {
            return try await withTaskCancellationHandler {
                try await withCheckedThrowingContinuation { continuation in
                    do {
                        try self.startRecognitionTask(
                            audioFileURL: absoluteURL,
                            continuation: continuation
                        )
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            } onCancel: {
                Task { await self.cancelCurrentTask() }
            }
        } catch let error as STTRepositoryError {
            throw error
        } catch {
            throw mapToRepositoryError(from: error)
        }
    }

    public nonisolated func checkSTTPermission() -> PermissionStatus {
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

    public func requestSTTPermission() async throws(STTPermissionRepositoryError) -> PermissionStatus {
        if Task.isCancelled { throw .cancelled }

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

    // MARK: - Private

    private func startRecognitionTask(
        audioFileURL: URL,
        continuation: CheckedContinuation<Transcript, any Error>
    ) throws(STTRepositoryError) {
        guard !Task.isCancelled else { throw .cancelled }
        
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "ko-KR")) else {
            AppLogger.error("SFSpeechRecognizer 초기화 실패 (ko-KR)")
            throw .transcribeFailed
        }

        if !recognizer.isAvailable {
            AppLogger.warning("SFSpeechRecognizer를 현재 사용할 수 없는 상태입니다. (isAvailable = false)")
        }

        let request = SFSpeechURLRecognitionRequest(url: audioFileURL)
        request.requiresOnDeviceRecognition = false
        currentContinuation = continuation

        currentTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }

            if let error {
                Task { await self.failTask(error) }
                return
            }

            guard let result, result.isFinal else { return }

            let transcription = result.bestTranscription
            let segments = transcription.segments.map {
                TranscriptSegment(
                    substring: $0.substring,
                    timestamp: $0.timestamp,
                    duration: $0.duration
                )
            }
            let transcript = Transcript(text: transcription.formattedString, segments: segments)
            AppLogger.info("음성 전사가 완료되었습니다. 글자 수: \(transcript.text.count)")
            Task { await self.finishTask(transcript) }
        }
    }

    private func finishTask(_ result: Transcript) {
        let continuation = currentContinuation
        currentContinuation = nil
        currentTask = nil
        continuation?.resume(returning: result)
    }

    private func failTask(_ error: Error) {
        let continuation = currentContinuation
        currentContinuation = nil
        currentTask = nil
        continuation?.resume(throwing: mapToRepositoryError(from: error))
    }

    private func cancelCurrentTask() {
        let continuation = currentContinuation
        currentContinuation = nil
        currentTask?.cancel()
        currentTask = nil
        AppLogger.info("음성 전사가 취소되었습니다.")
        continuation?.resume(throwing: STTRepositoryError.cancelled)
    }

    private func mapToRepositoryError(from error: Error) -> STTRepositoryError {
        if let repoError = error as? STTRepositoryError { return repoError }

        let nsError = error as NSError

        // Speech Framework의 사용자 취소 코드 (301)
        if nsError.domain == "com.apple.speech.speechrecognitionframework", nsError.code == 301 {
            return .cancelled
        }

        // 인식 결과가 없는 경우 (203)
        if nsError.domain == "kAFAssistantErrorDomain", nsError.code == 203 {
            return .transcribeFailed
        }

        // 추가 전사 오류 처리 (kLSRErrorDomain 300, kAFAssistantErrorDomain 1101)
        if nsError.domain == "kLSRErrorDomain", nsError.code == 300 {
            AppLogger.error("전사 실패: kLSRErrorDomain (300)")
            return .transcribeFailed
        }

        if nsError.domain == "kAFAssistantErrorDomain", nsError.code == 1101 {
            AppLogger.error("전사 실패: kAFAssistantErrorDomain (1101)")
            return .transcribeFailed
        }

        AppLogger.error("알 수 없는 전사 오류: \(error.localizedDescription) (Domain: \(nsError.domain), Code: \(nsError.code))")
        return .unknown(error)
    }
}
