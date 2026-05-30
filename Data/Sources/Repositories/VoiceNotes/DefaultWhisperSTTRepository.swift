import Core
import Domain
import Foundation
import Speech
import WhisperKit

public struct DefaultWhisperSTTRepository: STTRepository, @unchecked Sendable {
    private let storageService: any StorageService
    private let dataSource: any WhisperDataSource

    public init(
        storageService: any StorageService,
        dataSource: any WhisperDataSource
    ) {
        self.storageService = storageService
        self.dataSource = dataSource
    }

    public func transcribe(audioFilePath: String) async throws(STTRepositoryError) -> Transcript {
        guard !Task.isCancelled else { throw .cancelled }

        do {
            let audioURL = storageService.absoluteURL(for: audioFilePath)
            let result: [TranscriptionResult] = try await dataSource.transcribe(audioPath: audioURL)

            // Whisper 메모리 해제
            await dataSource.clearCache()

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
            await dataSource.clearCache()
            throw error
        } catch {
            await dataSource.clearCache()
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
