import Core
import Foundation

/// 음성 메모 통합 유스케이스 프로토콜.
public protocol VoiceNoteUseCase: Sendable {
    /// 새로운 음성 메모를 생성합니다.
    func create(_ voiceRecord: VoiceRecord) async throws(VoiceNoteUseCaseError) -> VoiceNote

    /// 기본 폴더의 모든 음성 메모를 조회합니다.
    func fetchAllFromDefaultFolder() async throws(VoiceNoteUseCaseError) -> [VoiceNote]

    /// 특정 폴더의 모든 음성 메모를 조회합니다.
    func fetchAll(folderID: UUID) async throws(VoiceNoteUseCaseError) -> [VoiceNote]

    /// 특정 음성 메모를 조회합니다.
    func fetch(byId id: UUID) async throws(VoiceNoteUseCaseError) -> VoiceNote

    /// 최근 생성된 음성 메모를 조회합니다.
    func fetchRecent(limit: Int) async throws(VoiceNoteUseCaseError) -> [VoiceNote]

    /// 음성 메모 정보를 업데이트합니다.
    func update(_ voiceNote: VoiceNote) async throws(VoiceNoteUseCaseError) -> VoiceNote

    /// 오디오 파일을 분석하여 전사·키워드·요약 결과를 반환합니다.
    func summarize(audioFilePath: String, language: Language) async throws(VoiceNoteUseCaseError)
        -> AudioToSummaryResult
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

    public func create(_ voiceRecord: VoiceRecord) async throws(VoiceNoteUseCaseError) -> VoiceNote {
        if Task.isCancelled { throw .cancelled }

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
            return try await repository.create(voiceRecord)
        } catch {
            throw VoiceNoteUseCaseError(error)
        }
    }

    // MARK: - Fetch

    public func fetchAllFromDefaultFolder() async throws(VoiceNoteUseCaseError) -> [VoiceNote] {
        if Task.isCancelled { throw .cancelled }
        do {
            return try await repository.fetchAllFromDefaultFolder()
        } catch {
            throw VoiceNoteUseCaseError(error)
        }
    }

    public func fetchAll(folderID: UUID) async throws(VoiceNoteUseCaseError) -> [VoiceNote] {
        if Task.isCancelled { throw .cancelled }
        do {
            return try await repository.fetchAll(folderID: folderID)
        } catch {
            throw VoiceNoteUseCaseError(error)
        }
    }

    public func fetch(byId id: UUID) async throws(VoiceNoteUseCaseError) -> VoiceNote {
        if Task.isCancelled { throw .cancelled }
        do {
            return try await repository.fetch(byId: id)
        } catch {
            throw VoiceNoteUseCaseError(error)
        }
    }

    public func fetchRecent(limit: Int) async throws(VoiceNoteUseCaseError) -> [VoiceNote] {
        if Task.isCancelled { throw .cancelled }
        do {
            return try await repository.fetchRecent(limit: limit)
        } catch {
            throw VoiceNoteUseCaseError(error)
        }
    }

    // MARK: - Update

    public func update(_ voiceNote: VoiceNote) async throws(VoiceNoteUseCaseError) -> VoiceNote {
        if Task.isCancelled { throw .cancelled }

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
            deletedAt: voiceNote.deletedAt
        )

        do {
            return try await repository.update(updatedNote)
        } catch {
            throw VoiceNoteUseCaseError(error)
        }
    }

    // MARK: - Analysis (Summarize)

    public func summarize(audioFilePath: String, language: Language) async throws(VoiceNoteUseCaseError)
        -> AudioToSummaryResult
    {
        do {
            try Task.checkCancellation()

            let transcript = try await sttRepository.transcribe(audioFilePath: audioFilePath)

            try Task.checkCancellation()

            let (keywords, summary) = try await summaryRepository.summarize(transcript: transcript, language: language)

            try Task.checkCancellation()

            return AudioToSummaryResult(
                transcript: transcript,
                keywords: keywords,
                summary: summary
            )
        } catch {
            if Task.isCancelled { throw .cancelled }
            AppLogger.error(error)
            throw VoiceNoteUseCaseError.analysisFailed(error)
        }
    }
}
