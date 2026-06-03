@testable import Domain
import Foundation
import XCTest

@MainActor
public final class MockAvailableModelSupportRepository: AvailableModelSupportRepository {
    public init() {}

    private var checkSupportModelResult: ChaGokModelSupport?
    private var downloadModelResult: Result<Void, AvailableModelSupportRepositoryError>?
    private var fetchSupportModelsResult: [ChaGokModelState] = []

    private var actualCheckSupportModelCallCount = 0
    private var actualDownloadModelCallCount = 0
    private var actualFetchSupportModelsCallCount = 0

    private var expectedCheckSupportModelCallCount: Int?
    private var expectedDownloadModelCallCount: Int?
    private var expectedFetchSupportModelsCallCount: Int?

    public func setCheckSupportModelResult(_ result: ChaGokModelSupport) {
        checkSupportModelResult = result
    }

    public func setDownloadModelResult(_ result: Result<Void, AvailableModelSupportRepositoryError>) {
        downloadModelResult = result
    }

    public func setFetchSupportModelsResult(_ result: [ChaGokModelState]) {
        fetchSupportModelsResult = result
    }

    public func expectCheckSupportModel(callCount: Int) {
        expectedCheckSupportModelCallCount = callCount
    }

    public func expectDownloadModel(callCount: Int) {
        expectedDownloadModelCallCount = callCount
    }

    public func expectFetchSupportModels(callCount: Int) {
        expectedFetchSupportModelsCallCount = callCount
    }

    public func verify(file: StaticString = #filePath, line: UInt = #line) {
        assertCount(
            actualCheckSupportModelCallCount,
            expectedCheckSupportModelCallCount,
            "checkSupportModel",
            file,
            line
        )
        assertCount(actualDownloadModelCallCount, expectedDownloadModelCallCount, "downloadModel", file, line)
        assertCount(
            actualFetchSupportModelsCallCount,
            expectedFetchSupportModelsCallCount,
            "fetchSupportModels",
            file,
            line
        )
    }

    private func assertCount(
        _ actual: Int,
        _ expected: Int?,
        _ label: String,
        _ file: StaticString,
        _ line: UInt
    ) {
        guard let expected else { return }
        XCTAssertEqual(actual, expected, "\(label) 호출 횟수 불일치", file: file, line: line)
    }

    public func checkMLXSupportModel() async -> ChaGokModelSupport {
        actualCheckSupportModelCallCount += 1
        if let result = checkSupportModelResult {
            return result
        }
        XCTFail("MockAvailableModelSupportRepository.checkSupportModelResult 미설정")
        return ChaGokModelSupport(ramSizeGB: 0)
    }

    public func downloadModel(
        progressHandler: @Sendable @escaping (Progress) -> Void
    ) async throws(AvailableModelSupportRepositoryError) {
        if Task.isCancelled { throw .cancelled }
        actualDownloadModelCallCount += 1

        switch downloadModelResult {
        case .success:
            let progress = Progress(totalUnitCount: 100)
            progress.completedUnitCount = 100
            progressHandler(progress)
            return
        case .failure(let error):
            throw error
        case .none:
            XCTFail("MockAvailableModelSupportRepository.downloadModelResult 미설정")
            throw .unknown(NSError(domain: "Mock", code: -1))
        }
    }

    public func fetchSupportModels() async -> [Domain.ChaGokModelState] {
        actualFetchSupportModelsCallCount += 1
        return fetchSupportModelsResult
    }
}
