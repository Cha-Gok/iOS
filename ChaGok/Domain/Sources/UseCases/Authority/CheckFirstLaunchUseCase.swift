import Foundation

// 사용자가 처음으로 사용하는지 판단하는 유즈케이스
public protocol CheckFirstLaunchUseCase: Sendable {
    /// True는 처음 사용하는 사용자 , False 는 기존 사용자
    /// - Parameter None
    /// - Returns: 신규 사용자 판단
    /// - Throws: None
    func execute() -> Bool
}

/// 사용자가 신규 사용자인지 판단합니다.
public struct DefaultCheckFirstLaunchUseCase: CheckFirstLaunchUseCase {
    let repository: CheckFirstLaunchRepository

    public func execute() -> Bool {
        repository.checkUser()
    }
}
