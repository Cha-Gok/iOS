import Domain
import Foundation

public struct DefaultCheckFirstLaunchRepository: CheckFirstLaunchRepository {
    private let store: any KeyValueStoreService

    public init(store: any KeyValueStoreService) {
        self.store = store
    }

    public func checkIsFirstLaunch() -> Bool {
        return store.bool(forKey: Policy.isExistingUserKey) != true
    }

    public func checkAndMarkFirstLaunch() -> Bool {
        let isFirstLaunch = checkIsFirstLaunch()
        if isFirstLaunch {
            store.set(true, forKey: Policy.isExistingUserKey)
        }
        return isFirstLaunch
    }
}
