import Foundation
@testable import Domain

/// DeleteRecordingsUseCase 테스트 전용 Mock.
actor MockVoiceRecordRepository: VoiceRecordRepository {

    // MARK: - deleteRecordings(olderThan:)

    var deleteRecordingsResult: Result<Int, Error> = .success(0)
    var deleteRecordingsCallCount = 0
    var lastDeleteRecordingsDate: Date?

    func setDeleteRecordings(_ result: Result<Int, Error>) {
        deleteRecordingsResult = result
    }

    // MARK: - delete(byId:)

    var deleteByIdError: Error?
    var deleteByIdCallCount = 0
    var lastDeleteById: UUID?

    func setDeleteByIdError(_ error: Error?) {
        deleteByIdError = error
    }

    // MARK: - VoiceRecordRepository (테스트에서 쓰는 메서드만 구현)

    func deleteRecordings(olderThan date: Date) async throws -> Int {
        deleteRecordingsCallCount += 1
        lastDeleteRecordingsDate = date
        return try deleteRecordingsResult.get()
    }

    func delete(byId id: UUID) async throws {
        deleteByIdCallCount += 1
        lastDeleteById = id
        if let error = deleteByIdError {
            throw error
        }
    }

    // MARK: - 나머지 프로토콜 요구사항 (UseCase 테스트에서 미사용)

    func save(_ recording: VoiceRecord) async throws -> VoiceRecord {
        recording
    }

    func fetchAll() async throws -> [VoiceRecord] {
        []
    }

    func fetch(byId id: UUID) async throws -> VoiceRecord? {
        nil
    }

    func fetchRecordings(olderThan date: Date) async throws -> [VoiceRecord] {
        []
    }

    func update(_ recording: VoiceRecord) async throws -> VoiceRecord {
        recording
    }
}
