import Core
import Foundation

/// 음성 메모 통합 유스케이스 프로토콜.
@MainActor
public protocol VoiceNoteUseCase: Sendable {
    /// 새로운 음성 메모를 생성하고 분석 파이프라인을 시작합니다.
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

    /// ID로 음성 메모를 관찰합니다. 첫 emit은 현재 상태이며, 이후 변경 시 재emit됩니다.
    func observe(id: UUID) throws(VoiceNoteUseCaseError) -> AsyncStream<VoiceNote>

    /// 특정 폴더의 음성 메모 목록을 관찰합니다. 첫 emit은 현재 상태이며, 이후 변경 시 재emit됩니다.
    func observe(folderID: UUID) throws(VoiceNoteUseCaseError) -> AsyncStream<[VoiceNote]>

    /// 기본 폴더의 음성 메모 목록을 관찰합니다. 첫 emit은 현재 상태이며, 이후 변경 시 재emit됩니다.
    func observeAllFromDefaultFolder() throws(VoiceNoteUseCaseError) -> AsyncStream<[VoiceNote]>

    /// 최근 생성된 음성 메모 목록을 관찰합니다. 첫 emit은 현재 상태이며, 이후 변경 시 재emit됩니다.
    func observeRecent(limit: Int) throws(VoiceNoteUseCaseError) -> AsyncStream<[VoiceNote]>

    /// 완료/실패 상태의 요약을 재생성합니다.
    func regenerateSummary(id: UUID)
}

/// 음성 메모 통합 유스케이스 구현체.
public struct DefaultVoiceNoteUseCase: VoiceNoteUseCase {
    private let repository: VoiceNoteRepository
    private let folderRepository: FolderRepository
    private let analysisService: any VoiceNoteAnalysisService

    public init(
        repository: VoiceNoteRepository,
        folderRepository: FolderRepository,
        analysisService: any VoiceNoteAnalysisService
    ) {
        self.repository = repository
        self.folderRepository = folderRepository
        self.analysisService = analysisService
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

        // 3. 기본 폴더 결정 (어느 폴더에 저장할지는 비즈니스 결정)
        let defaultFolder: Folder
        do {
            let folders = try folderRepository.fetchAll()
            guard let folder = folders.first(where: { $0.kind == .default }) else {
                throw VoiceNoteUseCaseError.unknown(VoiceNoteRepositoryError.defaultFolderNotFound)
            }
            defaultFolder = folder
        } catch let error as VoiceNoteUseCaseError {
            throw error
        } catch {
            AppLogger.error(error)
            throw .unknown(error)
        }

        // 4. VoiceNote 모델 구성 (제목 등 비즈니스 규칙은 UseCase에서 결정)
        let voiceNote = VoiceNote(
            title: voiceRecord.createdAt.yyyyMMddHHmmssString,
            createdAt: voiceRecord.createdAt,
            updatedAt: voiceRecord.createdAt,
            folderID: defaultFolder.id,
            voiceRecord: voiceRecord,
            analysisState: .pending
        )

        // 5. 영속화
        let created: VoiceNote
        do {
            created = try repository.create(voiceNote)
        } catch {
            throw VoiceNoteUseCaseError(error)
        }

        // 6. 분석 파이프라인 자동 시작 (fire-and-forget)
        analysisService.enqueue(voiceNoteID: created.id)
        return created
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

    public func observe(folderID: UUID) throws(VoiceNoteUseCaseError) -> AsyncStream<[VoiceNote]> {
        do {
            return try repository.observe(folderID: folderID)
        } catch {
            throw VoiceNoteUseCaseError(error)
        }
    }

    public func observeAllFromDefaultFolder() throws(VoiceNoteUseCaseError) -> AsyncStream<[VoiceNote]> {
        do {
            return try repository.observeAllFromDefaultFolder()
        } catch {
            throw VoiceNoteUseCaseError(error)
        }
    }

    public func observeRecent(limit: Int) throws(VoiceNoteUseCaseError) -> AsyncStream<[VoiceNote]> {
        do {
            return try repository.observeRecent(limit: limit)
        } catch {
            throw VoiceNoteUseCaseError(error)
        }
    }

    // MARK: - Analysis Facade

    public func regenerateSummary(id: UUID) {
        analysisService.regenerate(voiceNoteID: id)
    }
}
