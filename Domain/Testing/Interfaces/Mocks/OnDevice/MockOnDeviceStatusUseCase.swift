@testable import Domain
import Foundation
import XCTest

public final class MockOnDeviceStatusUseCase: OnDeviceStatusUseCase, @unchecked Sendable {
    public init() {}

    public var subscribeStream: AsyncStream<OnDeviceStatus>?
    public var downloadResult: Result<Void, OnDeviceStatusUseCaseError> = .success(())
    public var deleteResult: Result<OnDeviceStatus, DeleteOnDeviceRepositoryError> = .success(OnDeviceStatus(
        storage: .notDownloaded,
        runtime: .unloaded
    ))

    public var actualSubscribeCallCount = 0
    public var actualDownloadCallCount = 0
    public var actualDeleteCallCount = 0

    public var subscribedModel: ChaGokModel?
    public var downloadedModel: ChaGokModel?
    public var deletedModel: ChaGokModel?

    public func subscribe(model: ChaGokModel) async -> AsyncStream<OnDeviceStatus> {
        actualSubscribeCallCount += 1
        subscribedModel = model
        return subscribeStream ?? AsyncStream { $0.finish() }
    }

    public func download(model: ChaGokModel) async throws(OnDeviceStatusUseCaseError) {
        actualDownloadCallCount += 1
        downloadedModel = model
        switch downloadResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }

    public func delete(model: ChaGokModel) async throws(DeleteOnDeviceRepositoryError) {
        actualDeleteCallCount += 1
        deletedModel = model
        switch deleteResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }
}
