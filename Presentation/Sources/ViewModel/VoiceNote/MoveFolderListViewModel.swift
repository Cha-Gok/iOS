import Core
import Domain
import Foundation

public protocol MoveFolderListCoordinatorDelegate: BaseCoordinatorDelegate {
    func dismiss()
    func pushNewFolder()
}

@MainActor
@Observable
public final class MoveFolderListViewModel {
    public weak var coordinator: MoveFolderListCoordinatorDelegate?
    private(set) var state: State = .init()

    private let receive: Receive
    private let folderUseCase: any FolderUseCase
    private let voiceNoteUseCase: any VoiceNoteUseCase
    private let onDismiss: (() -> Void)?

    public init(
        receive: Receive,
        folderUseCase: any FolderUseCase,
        voiceNoteUseCase: any VoiceNoteUseCase,
        onDismiss: (() -> Void)? = nil
    ) {
        self.receive = receive
        self.folderUseCase = folderUseCase
        self.voiceNoteUseCase = voiceNoteUseCase
        self.onDismiss = onDismiss
    }

    func send(_ action: Action) {
        switch action {
        case let .view(viewAction):
            switch viewAction {
            case .onAppear:
                fetchFolders()
            case let .folderSelected(folder):
                state.selectedFolder = folder
            case .moveButtonTapped:
                moveVoiceNote()
            case .closeButtonTapped:
                coordinator?.dismiss()
            case .addFolderButtonTapped:
                coordinator?.pushNewFolder()
            }
        case let .internal(internalAction):
            switch internalAction {
            case let .foldersLoaded(folders):
                state.folders = folders
            }
        }
    }

    private func fetchFolders() {
        do {
            var voiceNote: VoiceNote = switch receive {
            case .single(let item):
                item
            case .multiple(let items):
                items.first!
            }
            let folders = try folderUseCase.fetchAll()
            let otherFolders = folders.filter { $0.id != voiceNote.folderID }
            send(.internal(.foldersLoaded(otherFolders)))
        } catch {
            AppLogger.error(error)
        }
    }

    private func moveVoiceNote() {
        guard let selectedFolder = state.selectedFolder else { return }
        do {
            switch receive {
            case .single(var voiceNote):
                voiceNote.folderID = selectedFolder.id
                _ = try voiceNoteUseCase.update(voiceNote)

            case .multiple(let voiceNotes):
                for var voiceNote in voiceNotes {
                    voiceNote.folderID = selectedFolder.id
                    _ = try voiceNoteUseCase.update(voiceNote)
                }
            }
            onDismiss?()
            coordinator?.dismiss()
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

    public enum Action {
        public enum View {
            case onAppear
            case folderSelected(Folder)
            case moveButtonTapped
            case closeButtonTapped
            case addFolderButtonTapped
        }

        public enum Internal {
            case foldersLoaded([Folder])
        }

        case view(View)
        case `internal`(Internal)
    }
}
