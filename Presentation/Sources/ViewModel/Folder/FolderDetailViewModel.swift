import Core
import Domain
import Foundation

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
    private(set) var items: [LibraryItem] = []
    private(set) var errorMessage: String?
    private(set) var selectedOrder: Order = .createdAt
    private(set) var isSelectionMode: Bool = false
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
    private func setSelectedOrder(_ order: Order) {
        selectedOrder = order
        sortItems()
    }

    private func sortItems() {
        switch selectedOrder {
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

    func toggleSelectionMode() {
        isSelectionMode.toggle()
        if !isSelectionMode {
            selectedItems.removeAll()
        }
    }

    func selectItem(_ item: VoiceNote) {
        selectedItems.insert(item, at: 0)
    }

    func deselectItem(_ item: VoiceNote) {
        selectedItems.removeAll { $0.id == item.id }
    }

    func touchCreatedAction() {
        setSelectedOrder(.createdAt)
    }

    func touchUpdatedAction() {
        setSelectedOrder(.updatedAt)
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
                let voiceNotes: [VoiceNote] = try await voiceNoteUseCase.fetchAll(folderID: folderID)
                self.items = voiceNotes.map { .voiceNote($0) }
                sortItems()
            } catch {
                AppLogger.error(error)
                errorMessage = error.localizedDescription
            }
        }
    }
}
