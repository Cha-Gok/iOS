import Domain
import Foundation

// MARK: - Coordinator Delegate 패턴

@MainActor
public protocol MainCoordinatorDelegate: AnyObject {
    /// 휴지통으로 push하는 함수
    func pushTrashView()
    /// 개인 폴더로 push 하는 함수
    func pushMyFolderView(category: CategoryToggle)
    /// 음성 노트로 push 하는 함수
    func pushVoiceNoteView(voiceNote: VoiceNote)
    /// 녹음 시작 present 함수
    func presentRecodingView()
    /// 공용 Pop함수
    func pop()
    /// 검색 화면 Push함수
    func pushSearchView(type: SearchViewModel.SearchType, items: [ContentItem])
    /// 설정 화면 push
    func pushSettingView()
}
