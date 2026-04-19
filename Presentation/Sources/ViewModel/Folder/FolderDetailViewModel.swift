import Core
import Domain
import Foundation

public protocol FolderDetailCoordinatorDelegate: BaseCoordinatorDelegate {
    /// 음성노트로 이동
    func pushVoiceNoteView(voiceNote: VoiceNote)
}

@MainActor
@Observable
public final class FolderDetailViewModel {
    // MARK: - State

    enum Select: Equatable {
        case none
        case all
        case single
    }

    enum Order {
        case createdAt
        case updatedAt
    }

    let title: String
    let folderID: UUID
    private(set) var items: [LibraryItem] = []
    private(set) var errorMessage: String?
    private(set) var order: Order = .createdAt
    private(set) var select: Select = .none
    private(set) var selectedItems: [VoiceNote] = []
    private(set) var showAlert: Bool = false

    public weak var coordinator: FolderDetailCoordinatorDelegate?

    // MARK: - UseCase

    private let voiceNoteUseCase: any VoiceNoteUseCase
    private let wasteBasketRepository: any WasteBasketRepository

    // MARK: - Initialize

    public init(
        title: String,
        folderID: UUID,
        voiceNoteUseCase: any VoiceNoteUseCase,
        wasteBasketRepository: any WasteBasketRepository
    ) {
        self.title = title
        self.folderID = folderID
        self.voiceNoteUseCase = voiceNoteUseCase
        self.wasteBasketRepository = wasteBasketRepository
        sortItems()
    }
}

// MARK: - Setter / Getter

extension FolderDetailViewModel {
    func setOrder(_ order: Order) {
        self.order = order
        sortItems()
    }

    func setSelectionMode(_ select: Select) {
        self.select = select
        if select == .none {
            allClearSelected()
        } else if select == .all {
            allSelected()
        }
    }

    func selectItem(_ item: VoiceNote) {
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
        coordinator?.presentFolderList(with: .multiple(selectedItems), dismiss: dismiss)
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
        showAlert = true
    }
}

// MARK: - Fetch

extension FolderDetailViewModel {
    func fetchItems() {
        Task {
            do {
                let voiceNotes: [VoiceNote] = try voiceNoteUseCase.fetchAll(folderID: folderID)
                self.items = voiceNotes.map { .voiceNote($0) }
                sortItems()
            } catch {
                AppLogger.error(error)
                errorMessage = error.localizedDescription
            }
        }
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
        let wasteBasketItems: [WasteBasketItem] = selectedItems.map { .voiceNote(obj: $0) }
        do {
            try wasteBasketRepository.moveAllToWasteBasket(items: wasteBasketItems)
            // 성공 시, 로컬 items에서 제거하여 UI에 즉시 반영
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
            let wasteBasket: WasteBasketItem = .voiceNote(obj: item)
            do {
                try wasteBasketRepository.restore(item: wasteBasket)
            } catch {
                AppLogger.error(error)
                errorMessage = error.errorDescription
            }
        }
        fetchItems()
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
                voiceNoteUseCase: PreviewVoiceNoteUseCase(items: previewData.items),
                wasteBasketRepository: PreviewWasteBasketRepository()
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
                        )
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
                    summary: nil
                )
            }

            func fetchAllFromDefaultFolder() throws(VoiceNoteUseCaseError) -> [VoiceNote] {
                items
            }

            func fetchAll(folderID: UUID) throws(VoiceNoteUseCaseError) -> [VoiceNote] {
                items.filter { $0.folderID == folderID }
            }

            func fetch(byId id: UUID) throws(VoiceNoteUseCaseError) -> VoiceNote {
                guard let item = items.first(where: { $0.id == id }) else {
                    throw .recordNotFound(id)
                }
                return item
            }

            func fetchRecent(limit: Int) throws(VoiceNoteUseCaseError) -> [VoiceNote] {
                Array(items.prefix(limit))
            }

            func update(_ voiceNote: VoiceNote) throws(VoiceNoteUseCaseError) -> VoiceNote {
                voiceNote
            }

            func transcribe(audioFilePath: String) async throws(VoiceNoteUseCaseError) -> Transcript {
                Transcript(text: "")
            }

            func summarize(
                transcript: Transcript,
                language: Language
            ) async throws(VoiceNoteUseCaseError) -> (keywords: [Keyword], summary: Summary) {
                (keywords: [], summary: Summary(text: ""))
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
        }

        final class PreviewWasteBasketRepository: WasteBasketRepository {
            private var wasteBasket: [WasteBasketItem] = []

            func allClear() throws(DeleteWasteBasketRepositoryError) {
                wasteBasket.removeAll()
                print("[Preview] 휴지통 비우기 완료")
            }

            func delete(item: WasteBasketItem) throws(DeleteWasteBasketRepositoryError) {
                wasteBasket.removeAll { $0 == item }
                print("[Preview] 영구 삭제: \(item)")
            }

            func deleteAll(items: [WasteBasketItem]) throws(DeleteWasteBasketRepositoryError) {
                let itemSet = Set(items)
                wasteBasket.removeAll { itemSet.contains($0) }
                print("[Preview] 영구 삭제: \(items.count)개")
            }

            func moveToWasteBasket(item: WasteBasketItem) throws(MoveWasteBasketRepositoryError) {
                wasteBasket.append(item)
                print("[Preview] 휴지통 이동: \(item)")
            }

            func moveAllToWasteBasket(items: [WasteBasketItem]) throws(MoveWasteBasketRepositoryError) {
                wasteBasket.append(contentsOf: items)
                print("[Preview] 휴지통 이동: \(items.count)개 (현재 휴지통: \(wasteBasket.count)개)")
            }

            func fetchAll() throws(FetchWasteBasketRepositoryError) -> [WasteBasketItem] {
                print("[Preview] 휴지통 조회: \(wasteBasket.count)개")
                return wasteBasket
            }

            func restore(item: WasteBasketItem) throws(RestoreWasteBasketRepositoryError) {
                wasteBasket.removeAll { $0 == item }
                print("[Preview] 복원: \(item)")
            }

            func restoreAll(items: [WasteBasketItem]) throws(RestoreWasteBasketRepositoryError) {
                let itemSet = Set(items)
                wasteBasket.removeAll { itemSet.contains($0) }
                print("[Preview] 복원: \(items.count)개")
            }
        }
    }

#endif
