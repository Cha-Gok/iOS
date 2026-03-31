@testable import Data
import XCTest

final class MockKeyValueStoreService: KeyValueStoreService, @unchecked Sendable {
    private var bools: [String: Bool] = [:]
    private var strings: [String: String] = [:]

    func bool(forKey key: String) -> Bool {
        bools[key] ?? false
    }

    func string(forKey key: String) -> String? {
        strings[key]
    }

    func set(_ value: Bool, forKey key: String) {
        bools[key] = value
    }

    func set(_ value: String, forKey key: String) {
        strings[key] = value
    }
}
