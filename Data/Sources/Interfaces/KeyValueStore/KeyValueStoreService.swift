/// UserDefaults 등 키-값 저장소에 대한 추상화 프로토콜.
public protocol KeyValueStoreService: Sendable {
    func bool(forKey key: String) -> Bool
    func string(forKey key: String) -> String?
    func set(_ value: Bool, forKey key: String)
    func set(_ value: String, forKey key: String)
}
