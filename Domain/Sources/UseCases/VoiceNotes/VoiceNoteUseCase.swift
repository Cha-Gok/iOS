import Core
import Foundation

/// 음성 메모 통합 유스케이스 프로토콜.
@MainActor
public protocol VoiceNoteUseCase: Sendable {
    /// 새로운 음성 메모를 생성합니다.
    func create(_ voiceRecord: VoiceRecord) throws(VoiceNoteUseCaseError) -> VoiceNote

    /// 기본 폴더의 모든 음성 메모를 조회합니다.
    func fetchAllFromDefaultFolder() throws(VoiceNoteUseCaseError) -> [VoiceNote]

    /// 특정 폴더의 모든 음성 메모를 조회합니다.
    func fetchAll(folderID: UUID) throws(VoiceNoteUseCaseError) -> [VoiceNote]

    /// 특정 음성 메모를 조회합니다.
    func fetch(byId id: UUID) throws(VoiceNoteUseCaseError) -> VoiceNote

    /// 최근 생성된 음성 메모를 조회합니다.
    func fetchRecent(limit: Int) throws(VoiceNoteUseCaseError) -> [VoiceNote]

    /// 음성 메모 정보를 업데이트합니다.
    func update(_ voiceNote: VoiceNote) throws(VoiceNoteUseCaseError) -> VoiceNote

    /// 오디오 파일을 전사하여 Transcript를 반환합니다.
    func transcribe(audioFilePath: String) async throws(VoiceNoteUseCaseError) -> Transcript

    /// Transcript를 분석하여 키워드와 요약을 반환합니다.
    func summarize(transcript: Transcript, language: Language) async throws(VoiceNoteUseCaseError)
        -> (keywords: [Keyword], summary: Summary)

    /// ID로 음성 메모를 관찰합니다. 첫 emit은 현재 상태이며, 이후 변경 시 재emit됩니다.
    func observe(id: UUID) throws(VoiceNoteUseCaseError) -> AsyncStream<VoiceNote>
}

/// 음성 메모 통합 유스케이스 구현체.
public struct DefaultVoiceNoteUseCase: VoiceNoteUseCase {
    private let repository: VoiceNoteRepository
    private let sttRepository: STTRepository
    private let summaryRepository: SummaryRepository

    public init(
        repository: VoiceNoteRepository,
        sttRepository: STTRepository,
        summaryRepository: SummaryRepository
    ) {
        self.repository = repository
        self.sttRepository = sttRepository
        self.summaryRepository = summaryRepository
    }

    // MARK: - Create

    public func create(_ voiceRecord: VoiceRecord) throws(VoiceNoteUseCaseError) -> VoiceNote {
        // 1. 녹음 시간 검증
        if !voiceRecord.duration.isFinite || voiceRecord.duration <= 0 {
            let error = VoiceNoteUseCaseError.invalidDuration(duration: voiceRecord.duration)
            AppLogger.error(error)
            throw error
        }

        // 2. 파일 이름 및 확장자 검증
        let fileName = (voiceRecord.audioFilePath as NSString).lastPathComponent
        if fileName.isEmpty {
            let error = VoiceNoteUseCaseError.emptyFileName
            AppLogger.error(error)
            throw error
        }

        let pathExtension = (voiceRecord.audioFilePath as NSString).pathExtension
        if AudioFileFormat(extension: pathExtension) == nil {
            let error = VoiceNoteUseCaseError.unsupportedExtension(pathExtension)
            AppLogger.error(error)
            throw error
        }

        do {
            return try repository.create(voiceRecord)
        } catch {
            throw VoiceNoteUseCaseError(error)
        }
    }

    // MARK: - Fetch

    public func fetchAllFromDefaultFolder() throws(VoiceNoteUseCaseError) -> [VoiceNote] {
        do {
            return try repository.fetchAllFromDefaultFolder()
        } catch {
            throw VoiceNoteUseCaseError(error)
        }
    }

    public func fetchAll(folderID: UUID) throws(VoiceNoteUseCaseError) -> [VoiceNote] {
        do {
            return try repository.fetchAll(folderID: folderID)
        } catch {
            throw VoiceNoteUseCaseError(error)
        }
    }

    public func fetch(byId id: UUID) throws(VoiceNoteUseCaseError) -> VoiceNote {
        do {
            return try repository.fetch(byId: id)
        } catch {
            throw VoiceNoteUseCaseError(error)
        }
    }

    public func fetchRecent(limit: Int) throws(VoiceNoteUseCaseError) -> [VoiceNote] {
        do {
            return try repository.fetchRecent(limit: limit)
        } catch {
            throw VoiceNoteUseCaseError(error)
        }
    }

    // MARK: - Update

    public func update(_ voiceNote: VoiceNote) throws(VoiceNoteUseCaseError) -> VoiceNote {
        // 1. 제목 유효성 검사 (공백)
        let trimmedTitle = voiceNote.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedTitle.isEmpty || voiceNote.title != trimmedTitle {
            throw .invalidTitle
        }

        // 2. 제목 길이 검사
        if trimmedTitle.count > Policy.maxNameLength {
            throw .invalidLengthTitle
        }

        // 3. 수정 시각 갱신 및 정보 보정
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
            deletedAt: voiceNote.deletedAt,
            analysisState: voiceNote.analysisState
        )

        do {
            return try repository.update(updatedNote)
        } catch {
            throw VoiceNoteUseCaseError(error)
        }
    }

    // MARK: - Observe

    public func observe(id: UUID) throws(VoiceNoteUseCaseError) -> AsyncStream<VoiceNote> {
        do {
            return try repository.observe(id: id)
        } catch {
            throw VoiceNoteUseCaseError(error)
        }
    }

    // MARK: - Transcribe

    public func transcribe(audioFilePath: String) async throws(VoiceNoteUseCaseError) -> Transcript {
        do {
            try Task.checkCancellation()
            return try await sttRepository.transcribe(audioFilePath: audioFilePath)
        } catch {
            if Task.isCancelled { throw .cancelled }
            AppLogger.error(error)
            throw VoiceNoteUseCaseError.analysisFailed(error)
        }
    }

    // MARK: - Summarize

    public func summarize(
        transcript: Transcript,
        language: Language
    ) async throws(VoiceNoteUseCaseError) -> (keywords: [Keyword], summary: Summary) {
        do {
            try Task.checkCancellation()
            return try await summaryRepository.summarize(transcript: transcript, language: language)
        } catch {
            if Task.isCancelled { throw .cancelled }
            AppLogger.error(error)
            throw VoiceNoteUseCaseError.analysisFailed(error)
        }
    }
}
