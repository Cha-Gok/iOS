import Core
import Foundation

/// 음성 메모 업데이트 유스케이스 프로토콜.
public protocol UpdateVoiceNoteUseCase: Sendable {
    /// 음성 메모 정보를 업데이트합니다.
    /// - Parameter voiceNote: 업데이트할 `VoiceNote` 엔티티
    /// - Returns: 업데이트된 `VoiceNote` 엔티티
    /// - Throws: `UpdateVoiceNoteUseCaseError` (업데이트 실패)
    func execute(_ voiceNote: VoiceNote) async throws(UpdateVoiceNoteUseCaseError) -> VoiceNote
}

public struct DefaultUpdateVoiceNoteUseCase: UpdateVoiceNoteUseCase {
    private let repository: VoiceNoteUpdateRepository

    public init(repository: VoiceNoteUpdateRepository) {
        self.repository = repository
    }

    public func execute(_ voiceNote: VoiceNote) async throws(UpdateVoiceNoteUseCaseError)
        -> VoiceNote
    {
        if Task.isCancelled {
            AppLogger.error("Task cancelled")
            throw .cancelled
        }

        // 1. 제목 유효성 검사 (공백)
        let trimmedTitle = voiceNote.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedTitle.isEmpty || voiceNote.title != trimmedTitle {
            throw .invalidTitle
        }

        // 2. 제목 길이 검사
        if trimmedTitle.count > Policy.maxNameLength {
            throw .invalidLengthTitle
        }

        // 3. 수정 시각 및 데이터 정합성 보정 (Updated 시각 갱신)
        let updatedNote = VoiceNote(
            id: voiceNote.id,
            title: trimmedTitle,
            createdAt: voiceNote.createdAt,
            updatedAt: Date.now,
            folderID: voiceNote.folderID,
            voiceRecord: voiceNote.voiceRecord,
            keywords: voiceNote.keywords,
            transcript: voiceNote.transcript,
            summary: voiceNote.summary,
            deletedAt: voiceNote.deletedAt
        )

        do {
            return try await repository.update(updatedNote)
        } catch {
            AppLogger.error(error)
            throw UpdateVoiceNoteUseCaseError(error)
        }
    }
}
