import Core
import Foundation

/// 음성 메모 생성 유스케이스 프로토콜.
public protocol CreateVoiceNoteUseCase: Sendable {
    /// 새로운 음성 메모를 생성합니다.
    /// - Parameter voiceRecord: 녹음 정보 (오디오 경로, 길이 등)
    /// - Returns: 저장된 `VoiceNote` 엔티티
    /// - Throws: `CreateVoiceNoteUseCaseError` (검증 실패, 리포지토리 생성 실패)
    func execute(_ voiceRecord: VoiceRecord) async throws(CreateVoiceNoteUseCaseError) -> VoiceNote
}

public struct DefaultCreateVoiceNoteUseCase: CreateVoiceNoteUseCase {
    private let repository: VoiceNoteCreateRepository

    public init(repository: VoiceNoteCreateRepository) {
        self.repository = repository
    }

    public func execute(_ voiceRecord: VoiceRecord) async throws(CreateVoiceNoteUseCaseError)
        -> VoiceNote
    {
        if Task.isCancelled { throw .cancelled }

        if !voiceRecord.duration.isFinite || voiceRecord.duration <= 0 {
            let error = CreateVoiceNoteUseCaseError.invalidDuration(duration: voiceRecord.duration)
            AppLogger.error(error)
            throw error
        }

        if !voiceRecord.audioFilePath.isFileURL {
            let error = CreateVoiceNoteUseCaseError.invalidAudioFilePath(voiceRecord.audioFilePath)
            AppLogger.error(error)
            throw error
        }

        let fileName = voiceRecord.audioFilePath.lastPathComponent
        if fileName.isEmpty {
            let error = CreateVoiceNoteUseCaseError.emptyFileName
            AppLogger.error(error)
            throw error
        }

        let pathExtension = voiceRecord.audioFilePath.pathExtension
        guard let _ = AudioFileFormat(extension: pathExtension) else {
            let error = CreateVoiceNoteUseCaseError.unsupportedExtension(pathExtension)
            AppLogger.error(error)
            throw error
        }

        do {
            return try await repository.create(voiceRecord)
        } catch {
            AppLogger.error(error)
            throw CreateVoiceNoteUseCaseError(error)
        }
    }
}

fileprivate extension CreateVoiceNoteUseCaseError {
    init(_ error: VoiceNoteCreateRepositoryError) {
        switch error {
        case .createFailed:
            self = .createFailed
        case .cancelled:
            self = .cancelled
        case .unknown:
            self = .unknown(error)
        }
    }
}
