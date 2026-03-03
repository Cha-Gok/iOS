import Foundation

/// 신규 사용자 여부를 판단하고 관리하는 리포지토리 프로토콜.
public protocol CheckFirstLaunchRepository: Sendable {
    /// 사용자가 처음 앱을 실행했는지 확인하고 필요한 상태 변경을 수행합니다.
    /// - Returns: 신규 사용자이면 true, 기존 사용자이면 false를 반환합니다.
    func checkUser() -> Bool
}

/// 내부 구현체에서 사용할 리포지토리 인터페이스입니다.
internal protocol InternalFirstLaunchRepository: CheckFirstLaunchRepository {
    // 신규 사용자라면 기존 사용자로 상태 변경.
    func setUser()

    // 사용자가 처음인지 판단한다.
    func getUser() -> Bool

}
