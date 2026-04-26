import Core
import Domain
import Foundation

@MainActor
public protocol FolderDetailCoordinatorDelegate: AnyObject {
    /// 뒤로 가기
    func pop()
    /// 음성 노트 가기
    func pushVoiceNoteView(voiceNote: VoiceNote)
    /// 폴더 이동 Sheet
    func presentFolderList(with voiceNotes: [VoiceNote], onComplete: ((String) -> Void)?)
    /// 검색 화면 Push함수
    func pushSearchView(type: SearchViewModel.SearchType, items: [ContentItem])
}

@MainActor
@Observable
public final class FolderDetailViewModel {
    // MARK: - State

    enum Order {
        case createdAt
        case updatedAt
    }

    let title: String
    let folderID: UUID
    private(set) var items: [ContentItem] = []
    private(set) var errorMessage: String?
    private(set) var order: Order = .createdAt
    private(set) var select: SelectionMode = .none
    private(set) var selectedItems: [VoiceNote] = []
    private(set) var showAlert: Bool = false

    public weak var coordinator: FolderDetailCoordinatorDelegate?

    @ObservationIgnored
    private var observationTask: Task<Void, Never>?

    // MARK: - UseCase

    private let voiceNoteUseCase: any VoiceNoteUseCase

    // MARK: - Initialize

    public init(
        title: String,
        folderID: UUID,
        voiceNoteUseCase: any VoiceNoteUseCase
    ) {
        self.title = title
        self.folderID = folderID
        self.voiceNoteUseCase = voiceNoteUseCase
        sortItems()
    }
}

// MARK: - Setter / Getter

extension FolderDetailViewModel {
    func setOrder(_ order: Order) {
        self.order = order
        sortItems()
    }

    func setSelectionMode(_ select: SelectionMode) {
        self.select = select
        if select == .none {
            allClearSelected()
        } else if select == .all {
            allSelected()
        }
    }

    func selectItem(_ item: VoiceNote) {
        if select == .none { setSelectionMode(.multiple) }
        selectedItems.append(item)
    }

    func deselectItem(_ item: VoiceNote) {
        selectedItems.removeAll { $0.id == item.id }
    }
}

// MARK: Action

extension FolderDetailViewModel {
    /// 뒤로가기
    func didTapBack() {
        coordinator?.pop()
    }

    /// 음성 노트 화면 전환
    func pushVoiceNote(voiceNote: VoiceNote) {
        coordinator?.pushVoiceNoteView(voiceNote: voiceNote)
    }

    /// 폴더 이동 Present
    func presentMoveFolder(dismiss: @escaping (String) -> Void) {
        guard !selectedItems.isEmpty else { return }
        coordinator?.presentFolderList(with: selectedItems, onComplete: dismiss)
    }

    /// 검색화면 이동
    func pushSearch() {
        coordinator?.pushSearchView(type: .myDetailFolder(title), items: items)
    }

    /// 전체 선택
    private func allSelected() {
        selectedItems = items.compactMap {
            if case .voiceNote(let voiceNote) = $0 { return voiceNote }
            return nil
        }
    }

    /// 전체 선택 해제
    private func allClearSelected() {
        selectedItems = []
    }

    func closeAlertView() {
        showAlert = false
    }

    func openAlertView() {
        guard !selectedItems.isEmpty else {
            setSelectionMode(.none)
            return
        }
        showAlert = true
    }
}

// MARK: - Lifecycle

extension FolderDetailViewModel {
    func onAppear() {
        guard observationTask == nil else { return }
        observationTask = Task { [weak self] in
            guard let self else { return }
            do {
                let stream = try voiceNoteUseCase.observe(folderID: folderID)
                for await voiceNotes in stream {
                    items = voiceNotes.map { .voiceNote($0) }
                    sortItems()
                }
            } catch {
                AppLogger.error(error)
                errorMessage = error.localizedDescription
            }
        }
    }

    func onDisappear() {
        observationTask?.cancel()
        observationTask = nil
    }

    private func sortItems() {
        switch order {
        case .createdAt:
            items.sort {
                switch ($0, $1) {
                case (.voiceNote(let l), .voiceNote(let r)):
                    return l.createdAt > r.createdAt
                default:
                    return false
                }
            }
        case .updatedAt:
            items.sort {
                switch ($0, $1) {
                case (.voiceNote(let l), .voiceNote(let r)):
                    return l.updatedAt > r.updatedAt
                default:
                    return false
                }
            }
        }
    }
}

// MARK: - Move ( delete )

extension FolderDetailViewModel {
    func move() {
        guard !selectedItems.isEmpty else { return }
        do {
            for note in selectedItems {
                try voiceNoteUseCase.moveToTrash(noteID: note.id)
            }
            let selectedIDs = Set(selectedItems.map(\.id))
            items.removeAll { item in
                if case .voiceNote(let v) = item { return selectedIDs.contains(v.id) }
                return false
            }
            setSelectionMode(.none)
        } catch {
            AppLogger.error(error)
            errorMessage = error.errorDescription
        }
    }
}

// MARK: - Restore (휴지통 이동 복구)

extension FolderDetailViewModel {
    func restore(items: [VoiceNote]) {
        for item in items {
            do {
                try voiceNoteUseCase.restore(noteID: item.id)
            } catch {
                AppLogger.error(error)
                errorMessage = error.errorDescription
            }
        }
    }
}

#if DEBUG
    extension FolderDetailViewModel {
        static func preview(
            title: String = "폴더 상세",
            folderID: UUID = UUID()
        ) -> FolderDetailViewModel {
            let previewData = PreviewData.make(folderID: folderID)

            return FolderDetailViewModel(
                title: title,
                folderID: folderID,
                voiceNoteUseCase: PreviewVoiceNoteUseCase(items: previewData.items)
            )
        }
    }

    private extension FolderDetailViewModel {
        struct PreviewData {
            let items: [VoiceNote]

            static func make(folderID: UUID, now: Date = .now) -> Self {
                let items: [VoiceNote] = (0 ..< 12).map { index in
                    let createdOffset = TimeInterval((index + 1) * 3600) * -1
                    let updatedOffset = TimeInterval((index + 1) * 1800) * -1
                    return VoiceNote(
                        title: "폴더 상세 메모 \(index + 1)",
                        createdAt: now.addingTimeInterval(createdOffset),
                        updatedAt: now.addingTimeInterval(updatedOffset),
                        folderID: folderID,
                        voiceRecord: VoiceRecord(
                            audioFilePath: "preview-\(index + 1).m4a",
                            duration: Double(90 + (index * 15))
                        ),
                        analysisState: .pending
                    )
                }
                return PreviewData(items: items)
            }
        }

        struct PreviewVoiceNoteUseCase: VoiceNoteUseCase {
            let items: [VoiceNote]

            func create(_ voiceRecord: VoiceRecord) throws(VoiceNoteUseCaseError) -> VoiceNote {
                VoiceNote(
                    title: "미리보기 기록",
                    createdAt: .now,
                    updatedAt: .now,
                    folderID: UUID(),
                    voiceRecord: voiceRecord,
                    keywords: [],
                    transcript: nil,
                    summary: nil,
                    analysisState: .pending
                )
            }

            func fetch(byId id: UUID) throws(VoiceNoteUseCaseError) -> VoiceNote {
                guard let item = items.first(where: { $0.id == id }) else {
                    throw .recordNotFound(id)
                }
                return item
            }

            func update(_ voiceNote: VoiceNote) throws(VoiceNoteUseCaseError) -> VoiceNote {
                voiceNote
            }

            func observe(id: UUID) throws(VoiceNoteUseCaseError) -> AsyncStream<VoiceNote> {
                guard let item = items.first(where: { $0.id == id }) else {
                    throw .recordNotFound(id)
                }
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

            func moveToTrash(noteID _: UUID) throws(VoiceNoteUseCaseError) {}
            func restore(noteID _: UUID) throws(VoiceNoteUseCaseError) {}
            func delete(noteID _: UUID) throws(VoiceNoteUseCaseError) {}
        }
    }

#endif
