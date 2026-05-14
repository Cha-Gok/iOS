import Core
import Domain
import Foundation
import Speech
import WhisperKit

public actor DefaultWhisperSTTRepository: STTRepository {
    private let whisperProvider: WhisperKitProvider

    public init(
        whisperProvider: WhisperKitProvider
    ) {
        self.whisperProvider = whisperProvider
    }

    @discardableResult
    public func download(
        progressHandler: (@Sendable (Progress) -> Void)? = nil
    ) async throws(STTRepositoryError) -> URL {
        let downloadBaseURL = await whisperProvider.downloadedBaseURL

        do {
            let recommendedModel: String = WhisperKit.recommendedModels().default
            AppLogger.info("추천하는 모델은 : \(recommendedModel)")
            let modelFolder = try await WhisperKit.download(
                variant: recommendedModel,
                downloadBase: downloadBaseURL,
                progressCallback: progressHandler
            )
            // 다운로드 후 캐시된 인스턴스를 초기화하여 다음 transcribe 시 새 모델을 로드하도록 함
            await whisperProvider.clearCache()
            return modelFolder
        } catch is CancellationError {
            throw .cancelled
        } catch {
            throw .unknown(error)
        }
    }

    public func transcribe(audioFilePath: String) async throws(STTRepositoryError) -> Transcript {
        guard !Task.isCancelled else { throw .cancelled }

        do {
            let result = try await whisperProvider.transcribe(
                audioFilePath: audioFilePath
            )

            let sections = Self.groupIntoSections(result.flatMap(\.segments))
            if !sections.isEmpty {
                return Transcript(sections: sections)
            }

            let text = result
                .map(\.text)
                .joined(separator: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { throw STTRepositoryError.transcribeFailed }
            return Transcript(sections: [TranscriptSection(timestamp: 0, text: text)])
        } catch let error as STTRepositoryError {
            throw error
        } catch {
            throw .unknown(error)
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
}

// MARK: - Private

fileprivate extension DefaultWhisperSTTRepository {
    private static func groupIntoSections(_ segments: [TranscriptionSegment]) -> [TranscriptSection] {
        var sections: [TranscriptSection] = []
        var currentTimestamp: TimeInterval?
        var currentTexts: [String] = []
        var previousEnd: TimeInterval?

        for segment in segments {
            let text = segment.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { continue }

            let start = TimeInterval(segment.start)
            let end = TimeInterval(segment.end)

            guard let timestamp = currentTimestamp else {
                currentTimestamp = start
                currentTexts = [text]
                previousEnd = end
                continue
            }

            let gap = max(0, start - (previousEnd ?? start))
            if gap > Policy.scriptGroupingPauseThreshold {
                let merged = currentTexts.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
                if !merged.isEmpty {
                    sections.append(TranscriptSection(timestamp: timestamp, text: merged))
                }
                currentTimestamp = start
                currentTexts = [text]
            } else {
                currentTexts.append(text)
            }

            previousEnd = end
        }

        if let timestamp = currentTimestamp {
            let merged = currentTexts.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
            if !merged.isEmpty {
                sections.append(TranscriptSection(timestamp: timestamp, text: merged))
            }
        }

        return sections
    }
}
