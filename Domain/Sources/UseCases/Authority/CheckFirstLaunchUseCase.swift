import Foundation

/// 사용자가 처음으로 사용하는지 판단하는 유즈케이스
public protocol CheckFirstLaunchUseCase: Sendable {
    /// 상태 변경 없이 신규 사용자 여부만 판단합니다.
    /// - Returns: 신규 사용자이면 true, 기존 사용자이면 false를 반환합니다.
    func checkIsFirstLaunch() -> Bool
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
}

/// 앱의 첫 실행 상태를 완료 처리하는 유즈케이스
public protocol CompleteFirstLaunchUseCase: Sendable {
    /// 첫 실행 여부를 확인하고 필요한 상태 변경을 수행합니다.
    /// - Returns: 호출 시점이 첫 실행이면 true, 기존 사용자면 false를 반환합니다.
    func execute() -> Bool
}

/// 사용자의 첫 실행 상태를 완료 처리합니다.
public struct DefaultCompleteFirstLaunchUseCase: CompleteFirstLaunchUseCase {
    private let repository: CheckFirstLaunchRepository

    public init(repository: CheckFirstLaunchRepository) {
        self.repository = repository
    }

    public func execute() -> Bool {
        repository.checkAndMarkFirstLaunch()
    }
}
