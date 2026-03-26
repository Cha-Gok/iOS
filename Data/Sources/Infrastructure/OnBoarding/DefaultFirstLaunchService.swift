import Domain
import Foundation

public final class DefaultFirstLaunchService: FirstLaunchService {
    public init() {}

    public func markAsLaunched() {
        UserDefaults.standard.set(true, forKey: Policy.isExistingUserKey)
    }

    public func isFirstLaunch() -> Bool {
        !UserDefaults.standard.bool(forKey: Policy.isExistingUserKey)
    }
}
