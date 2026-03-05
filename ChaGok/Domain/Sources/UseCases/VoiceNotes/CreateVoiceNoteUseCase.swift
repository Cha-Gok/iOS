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

    private let repository: VoiceNoteRepository

    public init(repository: VoiceNoteRepository) {
        self.repository = repository
    }

    public func execute(_ voiceRecord: VoiceRecord) async throws(CreateVoiceNoteUseCaseError) -> VoiceNote {
        if voiceRecord.duration < 0 {
            throw CreateVoiceNoteUseCaseError.invalidDuration(duration: voiceRecord.duration)
        }
        if !voiceRecord.audioFilePath.isFileURL || voiceRecord.audioFilePath.path.isEmpty {
            throw CreateVoiceNoteUseCaseError.invalidAudioFilePath(voiceRecord.audioFilePath)
        }
        do {
            return try await repository.create(voiceRecord)
        } catch {
            throw CreateVoiceNoteUseCaseError.repositoryFailed(error)
        }
    }
}
