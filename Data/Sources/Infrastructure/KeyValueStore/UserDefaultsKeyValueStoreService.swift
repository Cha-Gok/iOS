import Foundation

/// UserDefaults 기반 KeyValueStoreService 구현체.
public struct UserDefaultsKeyValueStoreService: KeyValueStoreService {
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func bool(forKey key: String) -> Bool? {
        defaults.object(forKey: key) as? Bool
    }

    public func string(forKey key: String) -> String? {
        defaults.string(forKey: key)
    }

    public func set(_ value: Bool, forKey key: String) {
        defaults.set(value, forKey: key)
    }

    public func set(_ value: String, forKey key: String) {
        defaults.set(value, forKey: key)
    }
}
