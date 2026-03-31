import Domain
import Foundation

public struct DefaultCheckFirstLaunchRepository: CheckFirstLaunchRepository {
    private let service: any FirstLaunchService

    public init(service: any FirstLaunchService) {
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
