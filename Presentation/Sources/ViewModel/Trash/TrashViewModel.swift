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

    private let repository: WasteBasketRepository

    // MARK: - Initialize

    public init(
        repository: WasteBasketRepository
    ) {
        self.repository = repository
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
        do {
            let wasteBaskets: [WasteBasketItem] = try repository.fetchAll()
            items = wasteBaskets.map(\.toLibraryItem)
        } catch {
            AppLogger.error(error)
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Delete

extension TrashViewModel {
    func deleteAll() {
        Task {
            do {
                try await repository.allClear()
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
                try await repository.delete(item: item)
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
                try await repository.deleteAll(items: deleteItems)
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
                try await repository.restore(item: item)
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
                try await repository.restoreAll(items: restoreItems)
                let restoreIDs = Set(restoreItems.map(\.id))
                items.removeAll { restoreIDs.contains($0.id) }
            } catch {
                AppLogger.error(error)
                errorMessage = error.localizedDescription
            }
        }
    }
}
