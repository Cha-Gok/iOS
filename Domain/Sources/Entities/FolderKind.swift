import Foundation

/// 폴더의 종류를 표현하는 enum.
public enum FolderKind: String, Sendable, Hashable, CaseIterable {
    /// 시스템이 생성하는 기본 폴더. 사용자 삭제/이름 변경 불가.
    case `default`
    /// 사용자가 직접 만든 폴더.
    case custom
    /// 휴지통(시스템 폴더). 휴지통 통합 시 활용 예정.
    case trash
}
