import Core
import Domain
import Foundation

public protocol MoveFolderListCoordinatorDelegate: BaseCoordinatorDelegate {
    func dismiss()
}

@MainActor
@Observable
public final class MoveFolderListViewModel {
    public weak var coordinator: MoveFolderListCoordinatorDelegate?
    private(set) var state: State = .init()

    private let voiceNote: VoiceNote
    private let fetchFolderUseCase: any FetchFolderUseCase
    private let updateVoiceNoteUseCase: any UpdateVoiceNoteUseCase

    public init(
        voiceNote: VoiceNote,
        fetchFolderUseCase: any FetchFolderUseCase,
        updateVoiceNoteUseCase: any UpdateVoiceNoteUseCase
    ) {
        self.voiceNote = voiceNote
        self.fetchFolderUseCase = fetchFolderUseCase
        self.updateVoiceNoteUseCase = updateVoiceNoteUseCase
    }

    func send(_ action: Action) {
        switch action {
        case let .view(viewAction):
            switch viewAction {
            case .onAppear:
                Task { await fetchFolders() }
            case let .folderSelected(folder):
                state.selectedFolder = folder
            case .moveButtonTapped:
                Task { await moveVoiceNote() }
            case .closeButtonTapped:
                coordinator?.dismiss()
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
            let otherFolders = folders.filter { $0.id != voiceNote.folderID }
            send(.internal(.foldersLoaded(folders)))
        } catch {
            AppLogger.error(error)
        }
    }

    private func moveVoiceNote() async {
        guard let selectedFolder = state.selectedFolder else { return }
        do {
            let updatedVoiceNote = VoiceNote(
                id: voiceNote.id,
                title: voiceNote.title,
                createdAt: voiceNote.createdAt,
                updatedAt: voiceNote.updatedAt,
                folderID: selectedFolder.id,
                voiceRecord: voiceNote.voiceRecord,
                keywords: voiceNote.keywords,
                transcript: voiceNote.transcript,
                summary: voiceNote.summary
            )
            _ = try await updateVoiceNoteUseCase.execute(updatedVoiceNote)
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
        }

        public enum Internal {
            case foldersLoaded([Folder])
        }

        case view(View)
        case `internal`(Internal)
    }
}
