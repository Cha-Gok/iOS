@testable import Domain
import Foundation
import XCTest

@MainActor
public final class MockOnDeviceRepository: OnDeviceRepository {
    public init() {}

    public var downloadResult: Result<Void, OnDeviceRepositoryError> = .success(())
    public var deleteResult: Result<OnDeviceStatus, DeleteOnDeviceRepositoryError> = .success(OnDeviceStatus(
        storage: .notDownloaded
    ))
    public var checkStatusResult: OnDeviceStatus = OnDeviceStatus(storage: .notDownloaded)

    public var downloadProgressValues: [Double] = []

    public var actualDownloadCallCount = 0
    public var actualDeleteCallCount = 0
    public var actualCheckStatusCallCount = 0

    public func download(progressHandler: @Sendable @escaping (Double) -> Void) async throws(OnDeviceRepositoryError) {
        actualDownloadCallCount += 1
        for val in downloadProgressValues {
            progressHandler(val)
        }
        switch downloadResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }

    public func delete() async throws(DeleteOnDeviceRepositoryError) -> OnDeviceStatus {
        actualDeleteCallCount += 1
        switch deleteResult {
        case .success(let status):
            return status
        case .failure(let error):
            throw error
        }
    }

    public func checkStatus() async -> OnDeviceStatus {
        actualCheckStatusCallCount += 1
        return checkStatusResult
    }
}
