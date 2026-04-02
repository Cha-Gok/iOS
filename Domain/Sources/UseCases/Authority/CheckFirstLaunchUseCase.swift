import Foundation

/// 사용자가 처음으로 사용하는지 판단하는 유즈케이스
public protocol CheckFirstLaunchUseCase: Sendable {
    /// 상태 변경 없이 신규 사용자 여부만 판단합니다.
    /// - Returns: 신규 사용자이면 true, 기존 사용자이면 false를 반환합니다.
    func checkIsFirstLaunch() -> Bool

    /// True는 처음 사용하는 사용자 , False 는 기존 사용자
    /// 상태를 확인하고 필요한 상태 변경을 함께 수행합니다.
    /// - Parameter None
    /// - Returns: 신규 사용자 판단
    /// - Throws: None
    func execute() -> Bool
}

/// 사용자가 신규 사용자인지 판단합니다.
public struct DefaultCheckFirstLaunchUseCase: CheckFirstLaunchUseCase {
    private let repository: CheckFirstLaunchRepository

    public init(repository: CheckFirstLaunchRepository) {
        self.repository = repository
    }

    public func checkIsFirstLaunch() -> Bool {
        repository.checkIsFirstLaunch()
    }

    public func execute() -> Bool {
        repository.checkAndMarkFirstLaunch()
    }
}
