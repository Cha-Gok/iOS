import Foundation

public struct StorageInfo {
    public let appUsedBytes: Int64
    public let deviceTotalBytes: Int64
    public let deviceUsedBytes: Int64

    public init(
        appUsedBytes: Int64,
        deviceTotalBytes: Int64,
        deviceUsedBytes: Int64
    ) {
        self.appUsedBytes = appUsedBytes
        self.deviceTotalBytes = deviceTotalBytes
        self.deviceUsedBytes = deviceUsedBytes
    }
}

extension StorageInfo: Sendable {}
extension StorageInfo: Equatable {}
