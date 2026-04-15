import Core
import Domain
import Foundation

@MainActor
@Observable
public final class MoveFolderListViewModel {
    private(set) var state: State = .init()

    private let fetchFolderUseCase: any FetchFolderUseCase

    public init(fetchFolderUseCase: any FetchFolderUseCase) {
        self.fetchFolderUseCase = fetchFolderUseCase
    }

    func send(_ action: Action) {
        switch action {
        case let .view(viewAction):
            switch viewAction {
            case .onAppear:
                Task { await fetchFolders() }
            case let .folderSelected(folder):
                state.selectedFolder = folder
            }
        case let .internal(internalAction):
            switch internalAction {
            case let .foldersLoaded(folders):
                state.folders = folders
            }
        }
    }

    private func fetchFolders() async {
        do {
            let folders = try await fetchFolderUseCase.fetchAll()
            send(.internal(.foldersLoaded(folders)))
        } catch {
            AppLogger.error(error)
        }
    }
}

extension MoveFolderListViewModel {
    struct State {
        let leftTitle = "이동할 폴더 선택"
        let addFolderButtonTitle = "새 폴더"
        let moveButtonTitle = "이동하기"
        var selectedFolder: Folder?
        var folders: [Folder] = []

        var isMoveButtonEnabled: Bool {
            selectedFolder != nil
        }
    }

    enum Action {
        enum View {
            case onAppear
            case folderSelected(Folder)
        }

        enum Internal {
            case foldersLoaded([Folder])
        }

        case view(View)
        case `internal`(Internal)
    }
}
