import Core
import Domain
import Foundation

@MainActor
public protocol FolderCoordinatorDelegate: AnyObject {
    func pop()
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
    private(set) var errorMessage: String?
    public weak var coordinator: FolderCoordinatorDelegate?

    // MARK: - Dependencies

    private let folderUseCase: any FolderUseCase

    // MARK: - Initialize

    public init(
        category: CategoryToggle,
        folderUseCase: any FolderUseCase
    ) {
        self.category = category
        self.folderUseCase = folderUseCase
    }
}

// MARK: - Setter / Getter

extension FolderViewModel {
    private func setMode(_ mode: TextFieldView.Mode) {
        self.mode = mode
    }

    func openTextField(for folder: Folder? = nil) {
        errorMessage = nil
        editFolder = folder
        setMode(folder == nil ? .create : .edit)
        showTextField = true
    }

    func closeTextField() {
        errorMessage = nil
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
        do {
            let folder = try folderUseCase.create(name: name)
            category.items.insert(.folder(folder), at: 0)
            closeTextField()
        } catch {
            AppLogger.error(error)
            errorMessage = error.errorDescription
        }
    }

    func fetchAll() {
        do {
            let folders: [Folder] = try folderUseCase.fetchDeletableFolders()
            let items: [ContentItem] = folders.map { .folder($0) }
            category.items = items
        } catch {
            AppLogger.error(error)
        }
    }

    func update(name: String) {
        guard let folder = editFolder else { return }

        let updatedFolder = Folder(
            id: folder.id,
            name: name,
            createdAt: folder.createdAt,
            voiceNoteIDs: folder.voiceNoteIDs,
            kind: folder.kind,
            deletedAt: folder.deletedAt
        )

        do {
            let updated = try folderUseCase.update(updatedFolder)
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
            errorMessage = error.errorDescription
        }
    }

    func move(folder: Folder) {
        do {
            try folderUseCase.moveToTrash(folderID: folder.id)
            category.items.removeAll {
                if case .folder(let obj) = $0 { return obj.id == folder.id }
                return false
            }
        } catch {
            AppLogger.error(error)
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
                items: previewData.folders.map(ContentItem.folder)
            )

            return FolderViewModel(
                category: category,
                folderUseCase: PreviewFolderUseCase(items: previewData.folders)
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
                        kind: .custom
                    )
                }
                return PreviewData(folders: folders)
            }
        }

        struct PreviewFolderUseCase: FolderUseCase {
            let items: [Folder]

            func create(name: String) throws(FolderUseCaseError) -> Folder {
                Folder(name: name, createdAt: .now, kind: .custom)
            }

            func createDefault() throws(FolderUseCaseError) -> Folder {
                Folder(name: "기본 폴더", kind: .default)
            }

            func createTrash() throws(FolderUseCaseError) -> Folder {
                Folder(name: "휴지통", kind: .trash)
            }

            func fetchAll() throws(FolderUseCaseError) -> [Folder] {
                items
            }

            func fetchDefault() throws(FolderUseCaseError) -> Folder {
                guard let folder = items.first(where: { $0.kind == .default }) else { throw .notFound }
                return folder
            }

            func fetchTrash() throws(FolderUseCaseError) -> Folder {
                guard let folder = items.first(where: { $0.kind == .trash }) else { throw .notFound }
                return folder
            }

            func fetchDeletableFolders() throws(FolderUseCaseError) -> [Folder] {
                items.filter { $0.kind == .custom }
            }

            func fetch(by id: UUID) throws(FolderUseCaseError) -> Folder {
                guard let item = items.first(where: { $0.id == id }) else { throw .notFound }
                return item
            }

            func update(_ folder: Folder) throws(FolderUseCaseError) -> Folder {
                folder
            }

            func observeDeletableFolders() throws(FolderUseCaseError) -> AsyncStream<[Folder]> {
                let snapshot = items.filter { $0.kind == .custom }
                return AsyncStream { continuation in
                    continuation.yield(snapshot)
                    continuation.finish()
                }
            }

            func observeDeleted() throws(FolderUseCaseError) -> AsyncStream<[Folder]> {
                AsyncStream { $0.finish() }
            }

            func moveToTrash(folderID _: UUID) throws(FolderUseCaseError) {}
            func restore(folderID _: UUID) throws(FolderUseCaseError) {}
            func delete(folderID _: UUID) throws(FolderUseCaseError) {}
        }
    }
#endif
