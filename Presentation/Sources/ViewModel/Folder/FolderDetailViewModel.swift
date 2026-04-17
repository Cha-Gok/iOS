import Core
import Domain
import Foundation

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
    var select: Select = .none
    private(set) var selectedItems: [VoiceNote] = []

    var isEmpty: Bool {
        items.isEmpty
    }

    public weak var coordinator: BaseCoordinatorDelegate?

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

    func setSelectionMode(_ select: Select) {
        self.select = select
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
    func didTapBack() {
        coordinator?.pop()
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

            func summarize(
                audioFilePath: String,
                language: Language
            ) async throws(VoiceNoteUseCaseError) -> AudioToSummaryResult {
                AudioToSummaryResult(
                    transcript: Transcript(text: ""),
                    keywords: [],
                    summary: Summary(text: "")
                )
            }
        }
    }
#endif
