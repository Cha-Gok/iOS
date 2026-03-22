import Domain
import Foundation

public final class DefaultCheckFirstUserService: CheckFirstUserService {
    public func setUser() {
        UserDefaults.standard.set(true, forKey: Policy.isExistingUserKey)
    }

    public func getFirstUser() -> Bool {
        !UserDefaults.standard.bool(forKey: Policy.isExistingUserKey)
    }
}
