import Core
import Domain
import Foundation

@MainActor
@Observable
public final class FolderViewModel {
    // MARK: - State

    var category: CategoryToggle
    public weak var coordinator: MainViewCoordinatorDelegate?
    private(set) var showAlert: Bool = false
    private(set) var editFolder: Folder?

    // MARK: - UseCase

    private let createUseCase: CreateFolderUseCase
    private let updateUseCase: UpdateFolderUseCase
    private let moveToTrashUseCase: MoveWasteBasketUseCase

    // MARK: - Initialize

    public init(
        category: CategoryToggle,
        createUseCase: CreateFolderUseCase,
        updateUseCase: UpdateFolderUseCase,
        moveToTrashUseCase: MoveWasteBasketUseCase
    ) {
        self.category = category
        self.createUseCase = createUseCase
        self.updateUseCase = updateUseCase
        self.moveToTrashUseCase = moveToTrashUseCase
    }
}

// MARK: - Setter / Getter

extension FolderViewModel {
    private func setEditFolder(_ folder: Folder?) {
        editFolder = folder
    }
}

// MARK: - Action

extension FolderViewModel {
    func didTapBack() {
        coordinator?.popMyFolderView()
    }

    func openTextFieldView(for folder: Folder? = nil) {
        setEditFolder(folder)
        showAlert = true
    }

    func closeTextFieldView() {
        editFolder = nil
        showAlert = false
    }
}

// MARK: - C R U D

extension FolderViewModel {
    /// Domain.Folder를 생성하는 함수
    func create(name: String) {
        closeTextFieldView()
        Task {
            do {
                let folder = try await createUseCase.execute(name: name)
                category.items.insert(.folder(folder), at: 0)
            } catch {
                AppLogger.error(error)
            }
        }
    }

    func update(name: String) {
        guard let folder = editFolder else { return }

        let updatedFolder = Folder(
            id: folder.id,
            name: name,
            createdAt: folder.createdAt,
            content: folder.content,
            isDeletable: folder.isDeletable,
            deletedAt: folder.deletedAt
        )

        closeTextFieldView()

        Task {
            do {
                let updated = try await updateUseCase.execute(updatedFolder)
                if let index = category.items.firstIndex(where: {
                    if case .folder(let folder) = $0 {
                        return folder.id == updated.id
                    }
                    return false
                }) {
                    category.items[index] = .folder(updated)
                }
            } catch {
                AppLogger.error(error)
            }
        }
    }

    func move(folder: Folder) {
        Task {
            do {
                try await moveToTrashUseCase.execute(method: .single(item: .folder(id: folder.id)))
                category.items.removeAll {
                    if case .folder(let item) = $0 { return item.id == folder.id }
                    return false
                }
            } catch {
                AppLogger.error(error)
            }
        }
    }
}
