import Core
import Domain
import Foundation
import Speech
import WhisperKit

public actor DefaultWhisperSTTRepository: STTRepository {
    private let whisperDataSource: any WhisperDataSource

    public init(
        whisperDataSource: any WhisperDataSource
    ) {
        self.whisperDataSource = whisperDataSource
    }

    @discardableResult
    public func download(
        progressHandler: (@Sendable (Progress) -> Void)? = nil
    ) async throws(STTRepositoryError) -> URL {
        let downloadBaseURL = await whisperDataSource.downloadedBaseURL

        do {
            let recommendedModel: String = WhisperKit.recommendedModels().default
            AppLogger.info("추천하는 모델은 : \(recommendedModel)")
            let modelFolder = try await WhisperKit.download(
                variant: recommendedModel,
                downloadBase: downloadBaseURL,
                progressCallback: progressHandler
            )
            // 다운로드 후 캐시된 인스턴스를 초기화하여 다음 transcribe 시 새 모델을 로드하도록 함
            await whisperDataSource.clearCache()
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
            let result = try await whisperDataSource.transcribe(
                audioFilePath: audioFilePath
            )
            await whisperDataSource.clearCache()

            let sections = result.flatMap(\.segments).map { segment in
                TranscriptSection(
                    timestamp: TimeInterval(segment.start),
                    text: segment.text.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            }.filter { !$0.text.isEmpty }
            
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
            await whisperDataSource.clearCache()
            throw error
        } catch {
            await whisperDataSource.clearCache()
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
