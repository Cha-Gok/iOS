import Core
import Domain
import Foundation

@MainActor
public protocol FolderCoordinatorDelegate: BaseCoordinatorDelegate {
    /// 개인 폴더 -> 상세 폴더 화면 이동 함수
    func pushMyFolderDetailView(_ folder: Folder)
}

@MainActor
@Observable
public final class FolderViewModel {
    // MARK: - State

    var category: CategoryToggle
    private(set) var showTextField: Bool = false
    private(set) var editFolder: Folder?
    private(set) var mode: TextFieldView.Mode = .create
    public weak var coordinator: FolderCoordinatorDelegate?

    // MARK: - Dependencies

    private let folderUseCase: any FolderUseCase
    private let wasteBasketRepository: WasteBasketRepository

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
    private func setMode(_ mode: TextFieldView.Mode) {
        self.mode = mode
    }

    func openTextField(for folder: Folder? = nil) {
        editFolder = folder
        setMode(folder == nil ? .create : .edit)
        showTextField = true
    }

    func closeTextField() {
        editFolder = nil
        setMode(.create)
        showTextField = false
    }
}

// MARK: - Action

extension FolderViewModel {
    func didTapBack() {
        coordinator?.pop()
    }

    func pushDetail(_ folder: Folder) {
        coordinator?.pushMyFolderDetailView(folder)
    }
}

// MARK: - C R U D

extension FolderViewModel {
    /// Domain.Folder를 생성하는 함수
    func create(name: String) {
        Task {
            do {
                let folder = try await folderUseCase.create(name: name)
                category.items.insert(.folder(folder), at: 0)
                closeTextField()
            } catch {
                AppLogger.error(error)
            }
        }
    }

    func fetchAll() {
        Task {
            do {
                let folders: [Folder] = try await fetchUseCase.fetchDeletableFolders()
                let items: [LibraryItem] = folders.map { .folder($0) }
                category.items = items
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

        Task {
            do {
                let updated = try await folderUseCase.update(updatedFolder)
                if let index = category.items.firstIndex(where: {
                    if case .folder(let folder) = $0 {
                        return folder.id == updated.id
                    }
                    return false
                }) {
                    category.items[index] = .folder(updated)
                }
                closeTextField()
            } catch {
                AppLogger.error(error)
            }
        }
    }

    func move(folder: Folder) {
        Task {
            do {
                try await wasteBasketRepository.moveToWasteBasket(item: .folder(obj: folder))
                category.items.removeAll {
                    if case .folder(let obj) = $0 { return obj.id == folder.id }
                    return false
                }
            } catch {
                AppLogger.error(error)
            }
        }
    }
}

#if DEBUG
    extension FolderViewModel {
        static func preview() -> FolderViewModel {
            let previewData = PreviewData.make()
            let category = CategoryToggle(
                imageName: "folder",
                title: "개인 폴더",
                items: previewData.folders.map(LibraryItem.folder)
            )

            return FolderViewModel(
                category: category,
                createUseCase: PreviewCreateFolderUseCase(),
                fetchUseCase: PreviewFetchFolderUseCase(items: previewData.folders),
                updateUseCase: PreviewUpdateFolderUseCase(),
                moveToTrashUseCase: PreviewMoveWasteBasketUseCase()
            )
        }
    }

    private extension FolderViewModel {
        struct PreviewData {
            let folders: [Folder]

            static func make(now: Date = .now) -> Self {
                let folders: [Folder] = (0 ..< 10).map { index in
                    let createdOffset = TimeInterval((index + 1) * 86400) * -1
                    return Folder(
                        name: "개인 폴더 \(index + 1)",
                        createdAt: now.addingTimeInterval(createdOffset),
                        content: [],
                        isDeletable: true
                    )
                }
                return PreviewData(folders: folders)
            }
        }

        struct PreviewCreateFolderUseCase: CreateFolderUseCase {
            func execute(name: String) async throws(CreateFolderUseCaseError) -> Folder {
                Folder(name: name, createdAt: .now, content: [], isDeletable: true)
            }
        }

        struct PreviewFetchFolderUseCase: FetchFolderUseCase {
            let items: [Folder]

            func fetchAll() async throws(FetchFolderUseCaseError) -> [Folder] {
                items
            }

            func fetchDeletableFolders() async throws(FetchFolderUseCaseError) -> [Folder] {
                items.filter(\.isDeletable)
            }

            func fetch(by id: UUID) async throws(FetchFolderUseCaseError) -> Folder {
                guard let item = items.first(where: { $0.id == id }) else {
                    throw .notFound
                }
                return item
            }
        }

        struct PreviewUpdateFolderUseCase: UpdateFolderUseCase {
            func execute(_ folder: Folder) async throws(UpdateFolderUseCaseError) -> Folder {
                folder
            }
        }

        struct PreviewMoveWasteBasketUseCase: MoveWasteBasketUseCase {
            func execute(method: MoveWasteBasketMethod) async throws(MoveWasteBasketUseCaseError) {
                // Preview 환경이므로 실제 삭제 로직은 수행하지 않습니다.
            }
        }
    }
#endif
