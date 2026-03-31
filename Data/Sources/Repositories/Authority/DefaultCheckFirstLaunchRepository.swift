import Domain
import Foundation

public struct DefaultCheckFirstLaunchRepository: CheckFirstLaunchRepository {
    private let store: any KeyValueStoreService

    public init(store: any KeyValueStoreService) {
        self.store = store
    }

    public func checkAndMarkFirstLaunch() -> Bool {
        let isFirstLaunch = store.bool(forKey: Policy.isExistingUserKey) != true
        if isFirstLaunch {
            store.set(true, forKey: Policy.isExistingUserKey)
        }
        return isFirstLaunch
    }
}
