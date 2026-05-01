import Core
import Domain
import Foundation

@MainActor
public protocol SearchCoordinatorDelegate: AnyObject {
    /// 뒤로 가기
    func pop()
    /// 폴더 Push
    func pushMyFolderDetailView(_ folder: Folder, isTrashMode: Bool)
    /// 음성 노트 Push
    func pushVoiceNoteView(voiceNote: VoiceNote)
}

@MainActor
@Observable
public final class SearchViewModel {
    // MARK: - Search State

    enum SearchState {
        case empty // 검색 전
        case emptyResult // 검색 결과 없음
        case result // 검색 결과 있음
    }

    public enum SearchType: Equatable {
        case main // 메인
        case myFolder // 폴더 목록
        case myDetailFolder(String) // 상세 폴더
        case trash // 휴지통

        var title: String {
            switch self {
            case .main:
                "전체"
            case .myFolder:
                "폴더 목록"
            case .myDetailFolder(let name):
                name
            case .trash:
                "휴지통"
            }
        }
    }

    // MARK: - State

    @ObservationIgnored
    private(set) var items: [ContentItem]
    @ObservationIgnored
    let type: SearchType
    public private(set) var isTrashMode: Bool = false
    private(set) var searchState: SearchState = .empty
    private(set) var filteredItems: [ContentItem] = []
    private(set) var query: String = ""
    public weak var coordinator: SearchCoordinatorDelegate?
    private let folderRepository: FolderRepository

    // MARK: Initialize

    public init(
        type: SearchType,
        items: [ContentItem],
        isTrashMode: Bool = false,
        folderRepository: FolderRepository
    ) {
        self.type = type
        self.items = items
        self.isTrashMode = isTrashMode
        self.folderRepository = folderRepository
    }

    // MARK: - Action

    func search(_ query: String) {
        self.query = query

        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchState = .empty
            filteredItems = []
            return
        }

        let results = items.filter { item in
            switch item {
            case .folder(let folder):
                return folder.name.localizedCaseInsensitiveContains(query)
            case .voiceNote(let voiceNote):
                return voiceNote.title.localizedCaseInsensitiveContains(query)
            }
        }

        filteredItems = results
        searchState = results.isEmpty ? .emptyResult : .result
    }

    func parentFolder(id: UUID) -> String {
        do {
            let folder: Folder = try folderRepository.fetch(by: id)
            return folder.name
        } catch {
            AppLogger.error(error)
        }

        return ""
    }

    func clearSearch() {
        coordinator?.pop()
    }

    // MARK: - Coordinator

    func pushFolder(_ folder: Folder) {
        coordinator?.pushMyFolderDetailView(folder, isTrashMode: isTrashMode)
    }

    func pushVoiceNote(_ voiceNote: VoiceNote) {
        coordinator?.pushVoiceNoteView(voiceNote: voiceNote)
    }
}

#if DEBUG
    public extension SearchViewModel {
        static func preview() -> SearchViewModel {
            SearchViewModel(
                type: .main,
                items: [
                    .folder(.init(name: "쓰레기 1")),
                    .folder(.init(name: "쓰레기 2")),
                    .folder(.init(name: "쓰레기 3")),
                    .voiceNote(
                        .init(
                            title: "음성",
                            folderID: UUID(),
                            voiceRecord: VoiceRecord(
                                audioFilePath: "qwe", duration: 23.0
                            ),
                            analysisState: .completed
                        )
                    )
                ],
                folderRepository: PreviewFolderRepository()
            )
        }
    }

    private struct PreviewFolderRepository: FolderRepository {
        func create(_ folder: Folder) throws(FolderRepositoryError) -> Folder {
            folder
        }

        func fetchAll() throws(FolderRepositoryError) -> [Folder] {
            []
        }

        func fetch(by id: UUID) throws(FolderRepositoryError) -> Folder {
            Folder(name: "미리보기 폴더", kind: .custom)
        }

        func fetch(by kind: FolderKind) throws(FolderRepositoryError) -> [Folder] {
            []
        }

        func update(_ folder: Folder) throws(FolderRepositoryError) -> Folder {
            folder
        }

        func observe(by kind: FolderKind) throws(FolderRepositoryError) -> AsyncStream<[Folder]> {
            AsyncStream { $0.finish() }
        }

        func observeTrashed() throws(FolderRepositoryError) -> AsyncStream<[Folder]> {
            AsyncStream { $0.finish() }
        }

        func delete(id: UUID) throws(FolderRepositoryError) {}
    }
#endif
