import Domain
import Foundation

@MainActor
public protocol BaseCoordinatorDelegate: AnyObject {
    /// 뒤로가기
    func pop()
    /// 폴더 Sheet 열기
    func presentFolderList(with: Receive, dismiss: ((String) -> Void)?)
}

public enum Receive: Hashable {
    case single(VoiceNote)
    case multiple([VoiceNote])
}

public extension BaseCoordinatorDelegate {
    func presentFolderList(with receive: Receive) {
        presentFolderList(with: receive, dismiss: nil)
    }
}
