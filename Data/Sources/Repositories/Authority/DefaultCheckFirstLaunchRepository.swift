import Domain
import Foundation

public final class DefaultCheckFirstLaunchRepository: CheckFirstLaunchRepository {
    private let service: FirstLaunchService

    public init(service: FirstLaunchService) {
        self.service = service
    }

    public func checkAndMarkFirstLaunch() -> Bool {
        let isFirstLaunch: Bool = service.isFirstLaunch()
        if isFirstLaunch { // 신규 사용자
            service.markAsLaunched()
            return true
        }

        return isFirstLaunch
    }
}
