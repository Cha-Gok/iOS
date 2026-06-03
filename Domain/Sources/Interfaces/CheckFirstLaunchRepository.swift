import Foundation

/// 신규 사용자 여부를 판단하고 관리하는 리포지토리 프로토콜.
public protocol CheckFirstLaunchRepository: Sendable {
    /// 사용자가 처음 앱을 실행했는지 확인만 합니다. (상태 변경 없음)
    /// - Returns: 신규 사용자이면 true, 기존 사용자이면 false를 반환합니다.
    func checkIsFirstLaunch() -> Bool

    /// 사용자가 처음 앱을 실행했는지 확인하고 필요한 상태 변경을 수행합니다.
    /// - Returns: 신규 사용자이면 true, 기존 사용자이면 false를 반환합니다.
    func checkAndMarkFirstLaunch() -> Bool
}
