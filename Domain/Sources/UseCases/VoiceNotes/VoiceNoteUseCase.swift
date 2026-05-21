import Core
import Foundation

/// 음성 메모 통합 유스케이스 프로토콜.
@MainActor
public protocol VoiceNoteUseCase: Sendable {
    /// 새로운 음성 메모를 생성하고 분석 파이프라인을 시작합니다.
    func create(_ voiceRecord: VoiceRecord) throws(VoiceNoteUseCaseError) -> VoiceNote

    /// 특정 음성 메모를 조회합니다.
    func fetch(byId id: UUID) throws(VoiceNoteUseCaseError) -> VoiceNote

    /// 음성 메모 정보를 업데이트합니다.
    func update(_ voiceNote: VoiceNote) throws(VoiceNoteUseCaseError) -> VoiceNote

    /// ID로 음성 메모를 관찰합니다. 첫 emit은 현재 상태이며, 이후 변경 시 재emit됩니다.
    func observe(id: UUID) throws(VoiceNoteUseCaseError) -> AsyncStream<VoiceNote>

    /// 특정 폴더의 음성 메모 목록을 관찰합니다. 첫 emit은 현재 상태이며, 이후 변경 시 재emit됩니다.
    func observe(folderID: UUID) throws(VoiceNoteUseCaseError) -> AsyncStream<[VoiceNote]>

    /// 최근 생성된 음성 메모 목록을 관찰합니다. 첫 emit은 현재 상태이며, 이후 변경 시 재emit됩니다.
    func observeRecent(limit: Int) throws(VoiceNoteUseCaseError) -> AsyncStream<[VoiceNote]>

    /// 휴지통에 단독 이동된 노트 목록을 관찰합니다.
    func observeTrashed() throws(VoiceNoteUseCaseError) -> AsyncStream<[VoiceNote]>

    /// 완료/실패 상태의 요약을 재생성합니다.
    func regenerateSummary(id: UUID)

    /// 노트를 휴지통으로 단독 이동합니다. 원본 폴더 정보는 `originalFolderID`에 보존됩니다.
    /// - Parameter noteID: 이동할 노트의 UUID
    func moveToTrash(noteID: UUID) throws(VoiceNoteUseCaseError)

    /// 휴지통에 있는 노트를 복원합니다.
    /// 원본 폴더가 살아있으면 원본으로, 아니면 기본 폴더로 복원합니다.
    /// - Parameter noteID: 복원할 노트의 UUID
    func restore(noteID: UUID) throws(VoiceNoteUseCaseError)

    /// 노트를 영구 삭제합니다.
    /// - Parameter noteID: 삭제할 노트의 UUID
    func delete(noteID: UUID) throws(VoiceNoteUseCaseError)
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
        let defaultFolders: [Folder]
        do {
            defaultFolders = try folderRepository.fetch(by: .default)
        } catch {
            AppLogger.error(error)
            throw .unknown(error)
        }
        guard let defaultFolder = defaultFolders.first else {
            throw .unknown(FolderRepositoryError.notFound)
        }

        // 4. VoiceNote 모델 구성 (제목 등 비즈니스 규칙은 UseCase에서 결정)
        let voiceNote = VoiceNote(
            title: Policy.voiceNoteDefaultName,
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
            AppLogger.error(error)
            throw VoiceNoteUseCaseError(error)
        }

        // 6. 분석 파이프라인 자동 시작 (fire-and-forget)
        analysisService.enqueue(voiceNoteID: created.id)
        return created
    }

    // MARK: - Fetch

    public func fetch(byId id: UUID) throws(VoiceNoteUseCaseError) -> VoiceNote {
        do {
            return try repository.fetch(byId: id)
        } catch {
            AppLogger.error(error)
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

        // 3. 수정 시각 갱신
        var updatedNote = voiceNote
        updatedNote.title = trimmedTitle
        updatedNote.updatedAt = .now

        do {
            return try repository.update(updatedNote)
        } catch {
            AppLogger.error(error)
            throw VoiceNoteUseCaseError(error)
        }
    }

    // MARK: - Observe

    public func observe(id: UUID) throws(VoiceNoteUseCaseError) -> AsyncStream<VoiceNote> {
        do {
            return try repository.observe(id: id)
        } catch {
            AppLogger.error(error)
            throw VoiceNoteUseCaseError(error)
        }
    }

    public func observe(folderID: UUID) throws(VoiceNoteUseCaseError) -> AsyncStream<[VoiceNote]> {
        do {
            return try repository.observe(folderID: folderID)
        } catch {
            AppLogger.error(error)
            throw VoiceNoteUseCaseError(error)
        }
    }

    public func observeRecent(limit: Int) throws(VoiceNoteUseCaseError) -> AsyncStream<[VoiceNote]> {
        do {
            return try repository.observeRecent(limit: limit)
        } catch {
            AppLogger.error(error)
            throw VoiceNoteUseCaseError(error)
        }
    }

    public func observeTrashed() throws(VoiceNoteUseCaseError) -> AsyncStream<[VoiceNote]> {
        do {
            return try repository.observeTrashed()
        } catch {
            AppLogger.error(error)
            throw VoiceNoteUseCaseError(error)
        }
    }

    // MARK: - Analysis Facade

    public func regenerateSummary(id: UUID) {
        analysisService.regenerate(voiceNoteID: id)
    }

    // MARK: - Trash

    public func moveToTrash(noteID: UUID) throws(VoiceNoteUseCaseError) {
        // 1. 휴지통 폴더 resolve
        let trashFolders: [Folder]
        do {
            trashFolders = try folderRepository.fetch(by: .trash)
        } catch {
            AppLogger.error(error)
            throw VoiceNoteUseCaseError(error)
        }
        guard let trashFolder = trashFolders.first else {
            throw .unknown(FolderRepositoryError.notFound)
        }

        // 2. 노트 fetch
        let note: VoiceNote
        do {
            note = try repository.fetch(byId: noteID)
        } catch {
            AppLogger.error(error)
            throw VoiceNoteUseCaseError(error)
        }

        // 3. 상태 전이: 원본 폴더 스냅샷 + 휴지통으로 이동
        var trashed = note
        trashed.originalFolderID = note.folderID
        trashed.folderID = trashFolder.id
        trashed.deletedAt = .now

        do {
            _ = try repository.update(trashed)
        } catch {
            AppLogger.error(error)
            throw VoiceNoteUseCaseError(error)
        }
    }

    public func restore(noteID: UUID) throws(VoiceNoteUseCaseError) {
        // 1. 노트 fetch
        let note: VoiceNote
        do {
            note = try repository.fetch(byId: noteID)
        } catch {
            AppLogger.error(error)
            throw VoiceNoteUseCaseError(error)
        }

        // 2. 복원 대상 폴더 결정: 원본이 살아있으면 원본, 아니면 기본 폴더
        let targetFolderID = try resolveRestoreTargetFolderID(for: note)

        // 3. 상태 전이: 폴더 복귀 + 삭제 흔적 초기화
        var restored = note
        restored.folderID = targetFolderID
        restored.deletedAt = nil
        restored.originalFolderID = nil

        do {
            _ = try repository.update(restored)
        } catch {
            AppLogger.error(error)
            throw VoiceNoteUseCaseError(error)
        }
    }

    public func delete(noteID: UUID) throws(VoiceNoteUseCaseError) {
        do {
            try repository.delete(id: noteID)
        } catch {
            AppLogger.error(error)
            throw VoiceNoteUseCaseError(error)
        }
    }

    private func resolveRestoreTargetFolderID(
        for note: VoiceNote
    ) throws(VoiceNoteUseCaseError) -> UUID {
        // 원본 폴더가 지정돼 있고 휴지통에 들어가지 않았다면 원본으로 복원
        if let originalID = note.originalFolderID {
            do {
                let original = try folderRepository.fetch(by: originalID)
                if original.deletedAt == nil {
                    return original.id
                }
            } catch {
                // 원본 폴더가 영구 삭제된 정상 경로(notFound)는 fallback 진행,
                // 그 외 시스템 에러(DB 연결 실패 등)는 묻지 않고 그대로 전파
                if case .notFound = error {
                    // fallback으로 진행
                } else {
                    AppLogger.error(error)
                    throw VoiceNoteUseCaseError(error)
                }
            }
        }

        // fallback: 기본 폴더
        let defaultFolders: [Folder]
        do {
            defaultFolders = try folderRepository.fetch(by: .default)
        } catch {
            AppLogger.error(error)
            throw VoiceNoteUseCaseError(error)
        }
        guard let defaultFolder = defaultFolders.first else {
            throw .unknown(FolderRepositoryError.notFound)
        }
        return defaultFolder.id
    }
}
