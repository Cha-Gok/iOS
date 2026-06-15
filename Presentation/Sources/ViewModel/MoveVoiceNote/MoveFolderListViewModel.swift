import Core
import Domain
import Foundation

@MainActor
public protocol MoveFolderListCoordinatorDelegate: AnyObject {
    func dismiss()
    func pushNewFolder()
}

@MainActor
@Observable
public final class MoveFolderListViewModel {
    public weak var coordinator: MoveFolderListCoordinatorDelegate?
    private(set) var state: State = .init()

    private let voiceNotes: [VoiceNote]
    private let folderUseCase: any FolderUseCase
    private let voiceNoteUseCase: any VoiceNoteUseCase
    private let onComplete: ((String) -> Void)?

    public init(
        voiceNotes: [VoiceNote],
        folderUseCase: any FolderUseCase,
        voiceNoteUseCase: any VoiceNoteUseCase,
        onComplete: ((String) -> Void)? = nil
    ) {
        self.voiceNotes = voiceNotes
        self.folderUseCase = folderUseCase
        self.voiceNoteUseCase = voiceNoteUseCase
        self.onComplete = onComplete
    }

    func send(_ action: Action) {
        switch action {
        case .view(let viewAction):
            switch viewAction {
            case .onAppear:
                fetchFolders()
            case .folderSelected(let folder):
                state.selectedFolder = folder
            case .moveButtonTapped:
                moveVoiceNote()
            case .closeButtonTapped:
                coordinator?.dismiss()
            case .addFolderButtonTapped:
                coordinator?.pushNewFolder()
            case .errorMessageDismissed:
                state.errorMessage = nil
            }
        case .internal(let internalAction):
            switch internalAction {
            case .foldersLoaded(let folders):
                state.folders = folders
            }
        }
    }

    private func fetchFolders() {
        do {
            guard let currentFolderID = voiceNotes.first?.folderID else { return }
            let folders = try folderUseCase.fetchAll()
            let otherFolders = folders.filter { $0.id != currentFolderID && $0.kind != .trash }
            send(.internal(.foldersLoaded(otherFolders)))
        } catch {
            AppLogger.error(error)
            state.errorMessage = error.localizedDescription
        }
    }

    private func moveVoiceNote() {
        guard let selectedFolder = state.selectedFolder else { return }
        do {
            for var voiceNote in voiceNotes {
                voiceNote.folderID = selectedFolder.id
                _ = try voiceNoteUseCase.update(voiceNote)
            }
            onComplete?(selectedFolder.name)
            coordinator?.dismiss()
        } catch {
            AppLogger.error(error)
            state.errorMessage = error.localizedDescription
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
        var errorMessage: String?

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
            case errorMessageDismissed
        }

        public enum Internal {
            case foldersLoaded([Folder])
        }

        case view(View)
        case `internal`(Internal)
    }
}
