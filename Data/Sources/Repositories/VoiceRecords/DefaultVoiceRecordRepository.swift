import Core
import Domain
import Foundation

public struct DefaultVoiceRecordRepository: VoiceRecordRepository {
    private let audioService: any AudioRecorderService
    private let storageService: any StorageService

    public init(
        audioService: any AudioRecorderService,
        storageService: any StorageService
    ) {
        self.audioService = audioService
        self.storageService = storageService
    }

    public func checkMicrophonePermission() async throws(VoiceRecordRepositoryError) -> PermissionStatus {
        if Task.isCancelled { throw .cancelled }
        return await audioService.checkPermission()
    }

    public func requestMicrophonePermission() async throws(VoiceRecordRepositoryError) -> PermissionStatus {
        if Task.isCancelled { throw .cancelled }
        return await audioService.requestPermission()
    }

    public func startRecording() async throws(VoiceRecordRepositoryError) -> AsyncStream<Waveform> {
        if Task.isCancelled { throw .cancelled }
        do {
            let fileName = "\(Int(Date.now.timeIntervalSince1970 * 1000)).m4a"
            let tempURL = try await storageService.generateTemporaryURL(fileName: fileName)
            return try await audioService.startRecording(at: tempURL)
        } catch {
            AppLogger.error(error)
            throw VoiceRecordRepositoryError(error)
        }
    }

    public func pauseRecording() async throws(VoiceRecordRepositoryError) {
        if Task.isCancelled { throw .cancelled }
        do {
            try await audioService.pauseRecording()
        } catch {
            AppLogger.error(error)
            throw VoiceRecordRepositoryError(error)
        }
    }

    public func resumeRecording() async throws(VoiceRecordRepositoryError) {
        if Task.isCancelled { throw .cancelled }
        do {
            try await audioService.resumeRecording()
        } catch {
            AppLogger.error(error)
            throw VoiceRecordRepositoryError(error)
        }
    }

    public func finishRecording() async throws(VoiceRecordRepositoryError) -> VoiceRecord {
        if Task.isCancelled { throw .cancelled }

        let recorded: RecordedAudio
        do {
            recorded = try await audioService.finishRecording()
        } catch {
            AppLogger.error(error)
            throw VoiceRecordRepositoryError(error)
        }

        if Task.isCancelled { throw .cancelled }

        do {
            let fileName = recorded.audioFilePath.lastPathComponent
            let permanentURL = try await storageService.moveFile(
                from: recorded.audioFilePath,
                toDirectory: "VoiceRecords",
                fileName: fileName
            )

            return VoiceRecord(
                createdAt: recorded.createdAt,
                audioFilePath: permanentURL,
                duration: recorded.duration
            )
        } catch {
            AppLogger.error(error)
            throw VoiceRecordRepositoryError(error)
        }
    }
}
