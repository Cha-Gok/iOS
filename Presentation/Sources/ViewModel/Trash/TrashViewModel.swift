import Core
import Domain
import Foundation

@MainActor
@Observable
public final class TrashViewModel {
    // MARK: - State

    private(set) var items: [WasteBasketItem] = []
    private(set) var errorMessage: String?

    var isEmpty: Bool {
        items.isEmpty
    }

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
    }
}

// MARK: - Fetch

extension TrashViewModel {
    func fetchItems() {
        Task {
            do {
                items = try await fetchUseCase.execute()
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
                items.removeAll { $0 == item }
            } catch {
                AppLogger.error(error)
                errorMessage = error.localizedDescription
            }
        }
    }

    func delete(items deleteItems: [WasteBasketItem]) {
        Task {
            do {
                try await deleteUseCase.execute(method: .multiple(items: deleteItems))
                let deleteSet = Set(deleteItems)
                items.removeAll { deleteSet.contains($0) }
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
                items.removeAll { $0 == item }
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
                let restoreSet = Set(restoreItems)
                items.removeAll { restoreSet.contains($0) }
            } catch {
                AppLogger.error(error)
                errorMessage = error.localizedDescription
            }
        }
    }
}
