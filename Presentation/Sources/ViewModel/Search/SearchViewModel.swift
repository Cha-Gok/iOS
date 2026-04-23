import Foundation
import Domain

public protocol SearchCoordinatorDelegate: BaseCoordinatorDelegate {}

@MainActor
@Observable
public final class SearchViewModel {

    // MARK: - Search State

    enum SearchState {
        case empty        // 검색 전
        case emptyResult  // 검색 결과 없음
        case result       // 검색 결과 있음
    }

    // MARK: - State

    private(set) var searchState: SearchState = .empty
    private(set) var filteredItems: [LibraryItem] = []
    private(set) var query: String = ""
    private weak var coordinator: SearchCoordinatorDelegate?
    
    // MARK: Initialize
    
    public init() {
        
    }
    
    // MARK: - Data (더미)

    let items: [LibraryItem] = [
        .folder(Folder(name: "여행 계획", createdAt: .now.addingTimeInterval(-86400), content: [], isDeletable: true)),
        .folder(Folder(name: "업무 미팅", createdAt: .now.addingTimeInterval(-172800), content: [], isDeletable: true)),
        .voiceNote(VoiceNote(
            title: "아이디어 스케치",
            createdAt: .now.addingTimeInterval(-3600),
            updatedAt: .now.addingTimeInterval(-3600),
            folderID: UUID(),
            voiceRecord: VoiceRecord(createdAt: .now.addingTimeInterval(-3600), audioFilePath: "", duration: 120),
            analysisState: .completed
        )),
        .voiceNote(VoiceNote(
            title: "주간 회의록",
            createdAt: .now.addingTimeInterval(-7200),
            updatedAt: .now.addingTimeInterval(-7200),
            folderID: UUID(),
            voiceRecord: VoiceRecord(createdAt: .now.addingTimeInterval(-7200), audioFilePath: "", duration: 300),
            analysisState: .completed
        )),
        .folder(Folder(name: "개인 프로젝트", createdAt: .now.addingTimeInterval(-259200), content: [], isDeletable: true)),
        .voiceNote(VoiceNote(
            title: "장보기 리스트",
            createdAt: .now.addingTimeInterval(-10800),
            updatedAt: .now.addingTimeInterval(-10800),
            folderID: UUID(),
            voiceRecord: VoiceRecord(createdAt: .now.addingTimeInterval(-10800), audioFilePath: "", duration: 45),
            analysisState: .completed
        ))
    ]

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
}
