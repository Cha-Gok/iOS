import Foundation

/// 내부 구현체에서 사용할 리포지토리 인터페이스입니다.
public protocol CheckFirstUserService: Sendable {
    /// 신규 사용자라면 기존 사용자로 상태 변경.
    func setUser()

    /// 사용자가 처음인지 판단한다.
    /// - Returns: 신규 사용자는 True, 기존 사용자는 First
    func getFirstUser() -> Bool
}
