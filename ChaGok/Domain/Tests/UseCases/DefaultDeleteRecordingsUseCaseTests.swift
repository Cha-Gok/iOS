import XCTest
@testable import Domain

/// RBICEP 원칙에 따른 DefaultDeleteRecordingsUseCase 테스트
/// - Right: 올바른 동작(삭제 개수 반환, byId 삭제) 검증
/// - Boundary: 경계 날짜, 0개 삭제, 빈 ID
/// - Inverse: 반환값·호출 여부 역검증
/// - Cross-check: Repository 호출 인자·횟수로 결과 교차 검증
/// - Error: Repository 에러 전파
/// - Performance: 메서드당 Repository 1회 호출
final class DefaultDeleteRecordingsUseCaseTests: XCTestCase {

    private var mockRepository: MockVoiceRecordRepository!
    private var useCase: DefaultDeleteRecordingsUseCase!

    override func setUp() {
        super.setUp()
        mockRepository = MockVoiceRecordRepository()
        useCase = DefaultDeleteRecordingsUseCase(voiceRecordRepository: mockRepository)
    }

    override func tearDown() {
        useCase = nil
        mockRepository = nil
        super.tearDown()
    }

    // MARK: - Right: deleteRecordings(olderThan:) → Repository 반환값 그대로 반환

    func test_deleteRecordings_성공시_Repository가_반환한_삭제_개수를_그대로_반환한다() async throws {
        // Given
        let date = Date()
        await mockRepository.setDeleteRecordings(.success(3))

        // When
        let count = try await useCase.deleteRecordings(olderThan: date)

        // Then
        XCTAssertEqual(count, 3)
    }

    func test_deleteRecording_byId_성공시_Repository_delete가_호출된다() async throws {
        // Given
        let id = "record-1"
        await mockRepository.setDeleteByIdError(nil)

        // When
        try await useCase.deleteRecording(byId: id)

        // Then (Right: 올바른 메서드가 호출되어 예외 없이 완료)
        let callCount = await mockRepository.deleteByIdCallCount
        XCTAssertEqual(callCount, 1)
    }

    // MARK: - Boundary: 경계 조건

    func test_deleteRecordings_삭제_개수가_0일_때_0을_반환한다() async throws {
        // Given
        let date = Date()
        await mockRepository.setDeleteRecordings(.success(0))

        // When
        let count = try await useCase.deleteRecordings(olderThan: date)

        // Then
        XCTAssertEqual(count, 0)
    }

    func test_deleteRecordings_경계_날짜_과거_전달_시_Repository에_동일_날짜가_전달된다() async throws {
        // Given
        let boundaryDate = Date.distantPast
        await mockRepository.setDeleteRecordings(.success(0))

        // When
        _ = try await useCase.deleteRecordings(olderThan: boundaryDate)

        // Then
        let passedDate = await mockRepository.lastDeleteRecordingsDate
        XCTAssertEqual(passedDate, boundaryDate)
    }

    func test_deleteRecording_빈_문자열_id_전달_시_Repository에_동일_id가_전달된다() async throws {
        // Given
        await mockRepository.setDeleteByIdError(nil)

        // When
        try await useCase.deleteRecording(byId: "")

        // Then (Boundary: 빈 ID도 그대로 전달)
        let passedId = await mockRepository.lastDeleteById
        XCTAssertEqual(passedId, "")
    }

    // MARK: - Inverse / Cross-check: 인자·횟수 검증

    func test_deleteRecordings_호출_시_deleteRecordings_인자와_1회_호출_교차_검증() async throws {
        // Given
        let date = Date(timeIntervalSince1970: 1_000_000)
        await mockRepository.setDeleteRecordings(.success(2))

        // When
        _ = try await useCase.deleteRecordings(olderThan: date)

        // Then
        let callCount = await mockRepository.deleteRecordingsCallCount
        let passedDate = await mockRepository.lastDeleteRecordingsDate
        XCTAssertEqual(callCount, 1, "deleteRecordings(olderThan:)가 정확히 1번 호출되어야 합니다")
        XCTAssertEqual(passedDate, date, "전달한 date가 Repository에 그대로 전달되어야 합니다")
    }

    func test_deleteRecording_호출_시_delete_byId_인자와_1회_호출_교차_검증() async throws {
        // Given
        let id = "target-id"
        await mockRepository.setDeleteByIdError(nil)

        // When
        try await useCase.deleteRecording(byId: id)

        // Then
        let callCount = await mockRepository.deleteByIdCallCount
        let passedId = await mockRepository.lastDeleteById
        XCTAssertEqual(callCount, 1, "delete(byId:)가 정확히 1번 호출되어야 합니다")
        XCTAssertEqual(passedId, id, "전달한 id가 Repository에 그대로 전달되어야 합니다")
    }

    // MARK: - Error: Repository 에러 전파

    func test_deleteRecordings_Repository_에러_시_에러가_그대로_전파된다() async {
        // Given
        struct TestError: Error, Equatable {}
        await mockRepository.setDeleteRecordings(.failure(TestError()))

        // When & Then
        do {
            _ = try await useCase.deleteRecordings(olderThan: Date())
            XCTFail("에러가 전파되어야 합니다")
        } catch {
            XCTAssertTrue(error is TestError, "에러 타입이 일치해야 합니다")
        }
    }

    func test_deleteRecording_Repository_에러_시_에러가_그대로_전파된다() async {
        // Given
        struct TestError: Error, Equatable {}
        await mockRepository.setDeleteByIdError(TestError())

        // When & Then
        do {
            try await useCase.deleteRecording(byId: "any")
            XCTFail("에러가 전파되어야 합니다")
        } catch {
            XCTAssertTrue(error is TestError, "에러 타입이 일치해야 합니다")
        }
    }

    // MARK: - Performance: 중복 호출 없음 (1회만 호출)

    func test_deleteRecordings_한_번_호출_시_Repository_한_번만_호출된다() async throws {
        await mockRepository.setDeleteRecordings(.success(1))
        _ = try await useCase.deleteRecordings(olderThan: Date())
        let count = await mockRepository.deleteRecordingsCallCount
        XCTAssertEqual(count, 1)
    }

    func test_deleteRecording_한_번_호출_시_Repository_한_번만_호출된다() async throws {
        await mockRepository.setDeleteByIdError(nil)
        try await useCase.deleteRecording(byId: "id")
        let count = await mockRepository.deleteByIdCallCount
        XCTAssertEqual(count, 1)
    }
}
