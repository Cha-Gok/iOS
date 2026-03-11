import Core
import Foundation

/// 음성 메모 생성 유스케이스 프로토콜.
public protocol CreateVoiceNoteUseCase: Sendable {
    /// 새로운 음성 메모를 생성합니다.
    /// - Parameter voiceRecord: 녹음 정보 (오디오 경로, 길이 등)
    /// - Returns: 저장된 `VoiceNote` 엔티티
    /// - Throws: `VoiceNoteUseCaseError` (검증 실패, 리포지토리 생성 실패)
    func execute(_ voiceRecord: VoiceRecord) async throws(VoiceNoteUseCaseError) -> VoiceNote
}

public struct DefaultCreateVoiceNoteUseCase: CreateVoiceNoteUseCase {

    private let repository: VoiceNoteCreateRepository

    public init(repository: VoiceNoteCreateRepository) {
        self.repository = repository
    }

    public func execute(_ voiceRecord: VoiceRecord) async throws(VoiceNoteUseCaseError) -> VoiceNote {
        do {
            if Task.isCancelled {
                throw VoiceNoteUseCaseError.cancelled
            }

            if voiceRecord.duration < 0 {
                let error = VoiceNoteUseCaseError.invalidDuration(duration: voiceRecord.duration)
                AppLogger.error(error)
                throw error
            }

            if !voiceRecord.audioFilePath.isFileURL || voiceRecord.audioFilePath.path.isEmpty {
                let error = VoiceNoteUseCaseError.invalidAudioFilePath(voiceRecord.audioFilePath)
                AppLogger.error(error)
                throw error
            }

            return try await repository.create(voiceRecord)
        } catch {
            AppLogger.error(error)
            throw CreateVoiceNoteUseCaseError(error)
        }
    }
}

extension CreateVoiceNoteUseCaseError {
    init(error: Error) {
        switch error {
        }
    }
}
