import Core
import Domain
import Foundation

@MainActor
public protocol NewFolderCoordinatorDelegate: AnyObject {
    func cancel()
    func folderCreated()
}

@MainActor
@Observable
public final class NewFolderViewModel {
    public weak var coordinator: NewFolderCoordinatorDelegate?
    private(set) var state: State = .init()

    private let folderUseCase: any FolderUseCase

    public init(folderUseCase: any FolderUseCase) {
        self.folderUseCase = folderUseCase
    }

    func send(_ action: Action) {
        switch action {
        case .view(let viewAction):
            switch viewAction {
            case .cancelButtonTapped:
                coordinator?.cancel()
            case .createButtonTapped(let name):
                createFolder(name: name)
            }
        }
    }

    func clearErrorMessage() {
        state.errorMessage = nil
    }

    private func createFolder(name: String) {
        do {
            _ = try folderUseCase.create(name: name)
            coordinator?.folderCreated()
        } catch {
            AppLogger.error(error)
            state.errorMessage = error.localizedDescription
        }
    }
}

extension NewFolderViewModel {
    struct State {
        var errorMessage: String?
    }

    public enum Action {
        public enum View {
            case cancelButtonTapped
            case createButtonTapped(name: String)
        }

        case view(View)
    }
}
