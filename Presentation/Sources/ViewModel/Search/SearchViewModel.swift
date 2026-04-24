import Domain
import Foundation

@MainActor
public protocol SearchCoordinatorDelegate: AnyObject {
    /// 뒤로 가기
    func pop()
    /// 폴더 Push
    func pushMyFolderDetailView(_ folder: Folder)
    /// 음성 노트 Push
    func pushVoiceNoteView(voiceNote: VoiceNote)
}

@MainActor
@Observable
public final class SearchViewModel {
    // MARK: - Search State

    enum SearchState {
        case empty                      // 검색 전
        case emptyResult                // 검색 결과 없음
        case result                     // 검색 결과 있음
    }
    
    public enum SearchType {
        case main                       // 메인
        case myFolder                   // 폴더 목록
        case myDetailFolder(String)     // 상세 폴더
        case trash                      // 휴지통
        
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
    private(set) var items: [LibraryItem]
    @ObservationIgnored
    let type: SearchType
    private(set) var searchState: SearchState = .empty
    private(set) var filteredItems: [LibraryItem] = []
    private(set) var query: String = ""
    public weak var coordinator: SearchCoordinatorDelegate?

    // MARK: Initialize

    public init(type: SearchType, items: [LibraryItem]) {
        self.type = type
        self.items = items
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

    func clearSearch() {
        coordinator?.pop()
    }
    
    // MARK: - Coordinator
    
    func pushFolder(_ folder: Folder) {
        coordinator?.pushMyFolderDetailView(folder)
    }
    
    func pushVoiceNote(_ voiceNote: VoiceNote) {
        coordinator?.pushVoiceNoteView(voiceNote: voiceNote)
    }
}
