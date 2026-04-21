import Core
import Domain
import Foundation
import Speech

/// 음성 인식(STT) 리포지토리 기본 구현체.
public actor DefaultSTTRepository: STTRepository {
    private let storageService: any StorageService
    private var currentTask: SFSpeechRecognitionTask?
    private var currentContinuation: CheckedContinuation<Transcript, any Error>?

    /// Speech Framework에 동시 요청이 들어가지 않도록 `transcribe`를 FIFO로 순차화한다.
    private var isBusy = false
    private var waiters: [Waiter] = []

    private struct Waiter: Sendable {
        let id: UUID
        let continuation: CheckedContinuation<Bool, Never>
    }

    public init(storageService: any StorageService) {
        self.storageService = storageService
    }

    public func transcribe(audioFilePath: String) async throws(STTRepositoryError) -> Transcript {
        guard !Task.isCancelled else { throw .cancelled }

        try await acquireSlot()
        defer { releaseSlot() }

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

    // MARK: - Slot Queue

    /// 슬롯을 확보한다. 이미 진행 중인 전사가 있으면 FIFO로 대기한다.
    /// 대기 중 호출자 Task가 취소되면 `.cancelled`를 던진다.
    private func acquireSlot() async throws(STTRepositoryError) {
        if !isBusy {
            isBusy = true
            return
        }
        let grantedSlot = await waitInQueue()
        if !grantedSlot { throw .cancelled }
    }

    /// FIFO 큐에 대기자를 추가하고 슬롯이 인계될 때까지 대기한다.
    /// 반환값이 `true`면 슬롯을 획득했다는 뜻이며, `false`면 대기 중 취소된 것이다.
    private func waitInQueue() async -> Bool {
        let id = UUID()
        return await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                waiters.append(Waiter(id: id, continuation: continuation))
            }
        } onCancel: {
            Task { await self.cancelWaiter(id: id) }
        }
    }

    /// 슬롯을 반환한다. 대기자가 있으면 `isBusy`를 유지한 채 다음 호출자에게 슬롯을 인계한다.
    private func releaseSlot() {
        guard !waiters.isEmpty else {
            isBusy = false
            return
        }
        waiters.removeFirst().continuation.resume(returning: true)
    }

    /// 대기 중 취소된 호출자를 큐에서 제거하고 `false`를 반환해 `.cancelled`로 빠지게 한다.
    private func cancelWaiter(id: UUID) {
        guard let index = waiters.firstIndex(where: { $0.id == id }) else { return }
        waiters.remove(at: index).continuation.resume(returning: false)
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
            let sections = Self.groupIntoSections(transcription.segments)
            let transcript = Transcript(sections: sections)
            AppLogger.info("음성 전사가 완료되었습니다. 섹션 수: \(sections.count)")
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

    private static func groupIntoSections(_ segments: [SFTranscriptionSegment]) -> [TranscriptSection] {
        guard let first = segments.first else { return [] }

        var sections: [TranscriptSection] = []
        var currentTimestamp = first.timestamp
        var currentWords: [String] = [first.substring]

        for i in 1 ..< segments.count {
            let prev = segments[i - 1]
            let curr = segments[i]
            let gap = curr.timestamp - (prev.timestamp + prev.duration)

            if gap > Policy.scriptGroupingPauseThreshold {
                let text = currentWords.joined(separator: " ")
                sections.append(TranscriptSection(timestamp: currentTimestamp, text: text))
                currentTimestamp = curr.timestamp
                currentWords = [curr.substring]
            } else {
                currentWords.append(curr.substring)
            }
        }

        if !currentWords.isEmpty {
            let text = currentWords.joined(separator: " ")
            sections.append(TranscriptSection(timestamp: currentTimestamp, text: text))
        }

        return sections
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

        AppLogger
            .error("알 수 없는 전사 오류: \(error.localizedDescription) (Domain: \(nsError.domain), Code: \(nsError.code))")
        return .unknown(error)
    }
}
