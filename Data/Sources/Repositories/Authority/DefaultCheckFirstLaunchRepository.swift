import Domain
import Foundation

public final class DefaultCheckFirstLaunchRepository: CheckFirstLaunchRepository {
    private let service: CheckFirstUserService

    public init(service: CheckFirstUserService) {
        self.service = service
    }

    public func checkAndMarkFirstLaunch() -> Bool {
        let firstUser: Bool = service.getFirstUser()
        if firstUser { // 신규 사용자
            service.setUser()
            return true
        }

        return firstUser
    }
}
