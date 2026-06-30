#if DEBUG
    import Domain
    import Foundation

    extension VoiceNoteViewModel {
        static func preview() -> VoiceNoteViewModel {
            let noteID = UUID()
            let voiceNote = VoiceNote(
                id: noteID,
                title: "미리보기 회의록",
                createdAt: Date.now.addingTimeInterval(-3600),
                updatedAt: Date.now.addingTimeInterval(-1800),
                folderID: UUID(),
                voiceRecord: VoiceRecord(audioFilePath: "preview.m4a", duration: 245),
                keywords: [
                    Keyword(noteID: noteID, word: "디자인"),
                    Keyword(noteID: noteID, word: "회의"),
                    Keyword(noteID: noteID, word: "마감"),
                    Keyword(noteID: noteID, word: "일정")
                ],
                transcript: Transcript(sections: [
                    TranscriptSection(
                        timestamp: 0,
                        text: "오늘 회의는 다음 주 디자인 마감 일정을 정리하는 자리였습니다."
                    ),
                    TranscriptSection(
                        timestamp: 45,
                        text: "주요 컴포넌트 세 가지를 먼저 마무리하기로 했고, 나머지 항목은 추후 논의합니다."
                    ),
                    TranscriptSection(
                        timestamp: 120,
                        text: "다음 미팅은 수요일 오후로 예정되어 있습니다."
                    )
                ]),
                summary: Summary(
                    text: "다음 주 디자인 마감 일정 확정\n주요 컴포넌트 세 가지 우선 처리\n수요일 오후 추가 미팅"
                ),
                analysisState: .completed
            )
            return VoiceNoteViewModel(
                voiceNote: voiceNote,
                voiceNoteUseCase: PreviewVoiceNoteUseCase(items: [voiceNote]),
                folderUseCase: PreviewFolderUseCase(),
                playbackRepository: PreviewPlaybackRepository(),
                availableSupportModelRepository: PreviewAvailableModelSupportRepository()
            )
        }
    }

    private struct PreviewVoiceNoteUseCase: VoiceNoteUseCase {
        let items: [VoiceNote]

        func create(_ voiceRecord: VoiceRecord) throws(VoiceNoteUseCaseError) -> VoiceNote {
            VoiceNote(
                title: "미리보기 기록",
                folderID: UUID(),
                voiceRecord: voiceRecord,
                analysisState: .pending
            )
        }

        func fetch(byId id: UUID) throws(VoiceNoteUseCaseError) -> VoiceNote {
            guard let item = items.first(where: { $0.id == id }) else { throw .recordNotFound(id) }
            return item
        }

        func update(_ voiceNote: VoiceNote) throws(VoiceNoteUseCaseError) -> VoiceNote {
            voiceNote
        }

        func observe(id: UUID) throws(VoiceNoteUseCaseError) -> AsyncStream<VoiceNote> {
            guard let item = items.first(where: { $0.id == id }) else { throw .recordNotFound(id) }
            return AsyncStream { continuation in
                continuation.yield(item)
                continuation.finish()
            }
        }

        func observe(folderID: UUID) throws(VoiceNoteUseCaseError) -> AsyncStream<[VoiceNote]> {
            let filtered = items.filter { $0.folderID == folderID }
            return AsyncStream { continuation in
                continuation.yield(filtered)
                continuation.finish()
            }
        }

        func observeRecent(limit: Int) throws(VoiceNoteUseCaseError) -> AsyncStream<[VoiceNote]> {
            let recent = Array(items.prefix(limit))
            return AsyncStream { continuation in
                continuation.yield(recent)
                continuation.finish()
            }
        }

        func observeTrashed() throws(VoiceNoteUseCaseError) -> AsyncStream<[VoiceNote]> {
            AsyncStream { $0.finish() }
        }

        func regenerateSummary(id _: UUID) {}

        func enqueue(id _: UUID) {}

        func moveToTrash(noteID _: UUID) throws(VoiceNoteUseCaseError) {}
        func restore(noteID _: UUID) throws(VoiceNoteUseCaseError) {}
        func delete(noteID _: UUID) throws(VoiceNoteUseCaseError) {}
    }

    private struct PreviewFolderUseCase: FolderUseCase {
        func create(name: String) throws(FolderUseCaseError) -> Folder {
            Folder(name: name, kind: .custom)
        }

        func createDefault() throws(FolderUseCaseError) -> Folder {
            Folder(name: "기본 폴더", kind: .default)
        }

        func createTrash() throws(FolderUseCaseError) -> Folder {
            Folder(name: "휴지통", kind: .trash)
        }

        func fetchAll() throws(FolderUseCaseError) -> [Folder] {
            [Folder(name: "기본 폴더", kind: .default)]
        }

        func fetchDefault() throws(FolderUseCaseError) -> Folder {
            Folder(name: "기본 폴더", kind: .default)
        }

        func fetchTrash() throws(FolderUseCaseError) -> Folder {
            Folder(name: "휴지통", kind: .trash)
        }

        func fetchDeletableFolders() throws(FolderUseCaseError) -> [Folder] {
            []
        }

        func fetch(by _: UUID) throws(FolderUseCaseError) -> Folder {
            Folder(name: "기본 폴더", kind: .default)
        }

        func update(_ folder: Folder) throws(FolderUseCaseError) -> Folder {
            folder
        }

        func observeCustom() throws(FolderUseCaseError) -> AsyncStream<[Folder]> {
            AsyncStream { continuation in
                continuation.yield([])
                continuation.finish()
            }
        }

        func observeTrashed() throws(FolderUseCaseError) -> AsyncStream<[Folder]> {
            AsyncStream { $0.finish() }
        }

        func moveToTrash(folderID _: UUID) throws(FolderUseCaseError) {}
        func restore(folderID _: UUID) throws(FolderUseCaseError) {}
        func delete(folderID _: UUID) throws(FolderUseCaseError) {}
    }

    private struct PreviewPlaybackRepository: VoiceRecordPlaybackRepository {
        func prepare(audioFilePath _: String)
            throws(VoiceRecordPlaybackRepositoryError) -> AsyncStream<AudioPlaybackState>
        {
            AsyncStream { continuation in
                continuation.yield(AudioPlaybackState(status: .idle, currentTime: 0, duration: 245))
                continuation.finish()
            }
        }

        func play() throws(VoiceRecordPlaybackRepositoryError) {}
        func pause() throws(VoiceRecordPlaybackRepositoryError) {}
        func seek(to _: TimeInterval) throws(VoiceRecordPlaybackRepositoryError) {}
        func stop() throws(VoiceRecordPlaybackRepositoryError) {}
    }

    private struct PreviewAvailableModelSupportRepository: AvailableModelSupportRepository {
        func checkMLXSupportModel() async -> ChaGokModelSupport {
            ChaGokModelSupport(ramSizeGB: 8, isProUser: false)
        }

        func fetchSupportModels() async -> [ChaGokModelState] {
            []
        }
    }

#endif
