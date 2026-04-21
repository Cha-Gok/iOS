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
                languageRepository: PreviewLanguageRepository(),
                playbackRepository: PreviewPlaybackRepository(),
                wasteBasketRepository: PreviewWasteBasketRepository()
            )
        }
    }

    private struct PreviewVoiceNoteUseCase: VoiceNoteUseCase {
        let items: [VoiceNote]

        func create(_ voiceRecord: VoiceRecord) throws(VoiceNoteUseCaseError) -> VoiceNote {
            VoiceNote(
                title: "미리보기 기록",
                folderID: UUID(),
                voiceRecord: voiceRecord
            )
        }

        func fetchAllFromDefaultFolder() throws(VoiceNoteUseCaseError) -> [VoiceNote] {
            items
        }

        func fetchAll(folderID _: UUID) throws(VoiceNoteUseCaseError) -> [VoiceNote] {
            items
        }

        func fetch(byId id: UUID) throws(VoiceNoteUseCaseError) -> VoiceNote {
            guard let item = items.first(where: { $0.id == id }) else { throw .recordNotFound(id) }
            return item
        }

        func fetchRecent(limit: Int) throws(VoiceNoteUseCaseError) -> [VoiceNote] {
            Array(items.prefix(limit))
        }

        func update(_ voiceNote: VoiceNote) throws(VoiceNoteUseCaseError) -> VoiceNote {
            voiceNote
        }

        func transcribe(audioFilePath _: String) async throws(VoiceNoteUseCaseError) -> Transcript {
            Transcript()
        }

        func summarize(
            transcript _: Transcript,
            language _: Language
        ) async throws(VoiceNoteUseCaseError) -> (keywords: [Keyword], summary: Summary) {
            (keywords: [], summary: Summary(text: ""))
        }

        func observe(id: UUID) throws(VoiceNoteUseCaseError) -> AsyncStream<VoiceNote> {
            guard let item = items.first(where: { $0.id == id }) else { throw .recordNotFound(id) }
            return AsyncStream { continuation in
                continuation.yield(item)
                continuation.finish()
            }
        }
    }

    private struct PreviewFolderUseCase: FolderUseCase {
        func create(name: String) throws(FolderUseCaseError) -> Folder {
            Folder(name: name, isDeletable: true)
        }

        func createDefault() throws(FolderUseCaseError) -> Folder {
            Folder(name: "기본 폴더", isDeletable: false)
        }

        func fetchAll() throws(FolderUseCaseError) -> [Folder] {
            [Folder(name: "기본 폴더", isDeletable: false)]
        }

        func fetchDeletableFolders() throws(FolderUseCaseError) -> [Folder] {
            []
        }

        func fetch(by _: UUID) throws(FolderUseCaseError) -> Folder {
            Folder(name: "기본 폴더", isDeletable: false)
        }

        func update(_ folder: Folder) throws(FolderUseCaseError) -> Folder {
            folder
        }
    }

    private struct PreviewLanguageRepository: LanguageRepository {
        func fetchLanguage() -> Language {
            .ko
        }

        func saveLanguage(_: Language) {}
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

    private struct PreviewWasteBasketRepository: WasteBasketRepository {
        func allClear() throws(DeleteWasteBasketRepositoryError) {}
        func delete(item _: WasteBasketItem) throws(DeleteWasteBasketRepositoryError) {}
        func deleteAll(items _: [WasteBasketItem]) throws(DeleteWasteBasketRepositoryError) {}
        func moveToWasteBasket(item _: WasteBasketItem) throws(MoveWasteBasketRepositoryError) {}
        func moveAllToWasteBasket(items _: [WasteBasketItem]) throws(MoveWasteBasketRepositoryError) {}
        func fetchAll() throws(FetchWasteBasketRepositoryError) -> [WasteBasketItem] {
            []
        }

        func restore(item _: WasteBasketItem) throws(RestoreWasteBasketRepositoryError) {}
        func restoreAll(items _: [WasteBasketItem]) throws(RestoreWasteBasketRepositoryError) {}
    }
#endif
