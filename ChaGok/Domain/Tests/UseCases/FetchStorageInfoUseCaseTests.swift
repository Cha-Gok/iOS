import XCTest
@testable import Domain

final class FetchStorageInfoUseCaseTests: XCTestCase {
    private var mockRepository: MockStorageRepository!
    private var useCase: DefaultFetchStorageInfoUseCase!

    override func setUp() {
        super.setUp()
        mockRepository = MockStorageRepository()
        useCase = DefaultFetchStorageInfoUseCase(storageRepository: mockRepository)
    }

    override func tearDown() {
        useCase = nil
        mockRepository = nil
        super.tearDown()
    }

    // MARK: - 1.1 성공 시 Repository가 반환한 StorageInfo가 그대로 반환된다

    func test_실행_성공시_저장정보_그대로_반환한다() async throws {
        // Given
        let expectedStorageInfo = StorageInfo(
            appUsedBytes: 1_000_000,
            deviceTotalBytes: 128_000_000_000,
            deviceUsedBytes: 64_000_000_000
        )
        await mockRepository.putStorageInfo(.success(expectedStorageInfo))

        // When
        let result = try await useCase.execute()

        // Then
        XCTAssertEqual(result, expectedStorageInfo)
    }

    // MARK: - 1.2 실패 시 Repository가 던진 에러가 그대로 전파된다

    func test_실행_실패시_에러가_그대로_전파된다() async {
        // Given
        struct TestError: Error, Equatable {}
        let expectedError = TestError()
        await mockRepository.putStorageInfo(.failure(expectedError))

        // When & Then
        do {
            _ = try await useCase.execute()
            XCTFail("에러가 전파되어야 합니다")
        } catch {
            XCTAssertTrue(error is TestError, "에러 타입이 일치해야 합니다")
        }
    }

    // MARK: - 1.3 execute() 호출 시 fetchStorageInfo()가 정확히 1번 호출된다

    func test_실행시_fetchStorageInfo_한_번만_호출된다() async throws {
        // Given
        let expectedStorageInfo = StorageInfo(
            appUsedBytes: 500_000,
            deviceTotalBytes: 64_000_000_000,
            deviceUsedBytes: 32_000_000_000
        )
        await mockRepository.putStorageInfo(.success(expectedStorageInfo))

        // When
        _ = try await useCase.execute()

        // Then
        let storageInfoCallCount = await mockRepository.fetchStorageInfoCallCount
        XCTAssertEqual(storageInfoCallCount, 1, "fetchStorageInfo()가 정확히 1번 호출되어야 합니다")
    }
}
