import Core
import Domain
import Foundation

@MainActor
@Observable
public final class TrashViewModel {
    // MARK: - State

    enum Order {
        case createdAt
        case updatedAt
    }

    private(set) var items: [LibraryItem] = []
    private(set) var errorMessage: String?
    private(set) var selectedOrder: Order = .createdAt
    private(set) var isSelectionMode: Bool = false
    private(set) var selectedItems: [WasteBasketItem] = []
    private(set) var showAlert: Bool = false

    var isEmpty: Bool {
        items.isEmpty
    }

    public weak var coordinator: BaseCoordinatorDelegate?

    // MARK: - UseCase

    private let fetchUseCase: FetchWasteBasketFolderUseCase
    private let deleteUseCase: DeleteWasteBasketUseCase
    private let restoreUseCase: RestoreWasteBasketUseCase

    // MARK: - Initialize

    public init(
        fetchUseCase: FetchWasteBasketFolderUseCase,
        deleteUseCase: DeleteWasteBasketUseCase,
        restoreUseCase: RestoreWasteBasketUseCase
    ) {
        self.fetchUseCase = fetchUseCase
        self.deleteUseCase = deleteUseCase
        self.restoreUseCase = restoreUseCase
        sortItems()
    }
}

// MARK: - Setter / Getter

extension TrashViewModel {
    private func setSelectedOrder(_ order: Order) {
        selectedOrder = order
        sortItems()
    }

    private func sortItems() {
        switch selectedOrder {
        case .createdAt:
            items.sort { $0.createdAt > $1.createdAt }
        case .updatedAt:
            items.sort { $0.updatedAt > $1.updatedAt }
        }
    }

    func toggleSelectionMode() {
        isSelectionMode.toggle()
        if !isSelectionMode {
            delete(items: selectedItems)
            selectedItems.removeAll()
        }
    }

    func toggleShowAlert() {
        showAlert.toggle()
    }

    func selectItem(_ item: WasteBasketItem) {
        selectedItems.insert(item, at: 0)
    }

    func deselectItem(_ item: WasteBasketItem) {
        selectedItems.removeAll { $0 == item }
    }

    func touchCreatedAction() {
        setSelectedOrder(.createdAt)
    }

    func touchUpdatedAction() {
        setSelectedOrder(.updatedAt)
    }
}

// MARK: Action

extension TrashViewModel {
    func didTapBack() {
        coordinator?.pop()
    }
}

// MARK: - Fetch

extension TrashViewModel {
    func fetchItems() {
        Task {
            do {
                let wasteBaskets: [WasteBasketItem] = try await fetchUseCase.execute()
                self.items = wasteBaskets.map(\.toLibraryItem)
            } catch {
                AppLogger.error(error)
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Delete

extension TrashViewModel {
    func deleteAll() {
        Task {
            do {
                try await deleteUseCase.execute(method: .all)
                items.removeAll()
            } catch {
                AppLogger.error(error)
                errorMessage = error.localizedDescription
            }
        }
    }

    func delete(item: WasteBasketItem) {
        Task {
            do {
                try await deleteUseCase.execute(method: .single(item: item))
                items.removeAll { $0.id == item.id }
            } catch {
                AppLogger.error(error)
                errorMessage = error.localizedDescription
            }
        }
    }

    private func delete(items deleteItems: [WasteBasketItem]) {
        Task {
            do {
                try await deleteUseCase.execute(method: .multiple(items: deleteItems))
                let deleteIDs = Set(deleteItems.map(\.id))
                items.removeAll { deleteIDs.contains($0.id) }
            } catch {
                AppLogger.error(error)
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Restore

extension TrashViewModel {
    func restore(item: WasteBasketItem) {
        Task {
            do {
                try await restoreUseCase.execute(method: .single(item: item))
                items.removeAll { $0.id == item.id }
            } catch {
                AppLogger.error(error)
                errorMessage = error.localizedDescription
            }
        }
    }

    func restore(items restoreItems: [WasteBasketItem]) {
        Task {
            do {
                try await restoreUseCase.execute(method: .multiple(items: restoreItems))
                let restoreIDs = Set(restoreItems.map(\.id))
                items.removeAll { restoreIDs.contains($0.id) }
            } catch {
                AppLogger.error(error)
                errorMessage = error.localizedDescription
            }
        }
    }
}
