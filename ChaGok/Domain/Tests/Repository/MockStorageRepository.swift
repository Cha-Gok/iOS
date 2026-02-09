import Foundation
@testable import Domain

/// StorageRepository 프로토콜 계약 검증 및 호출부 테스트용 Mock.
final class MockStorageRepository: StorageRepository {

    var storageInfoResult: Result<StorageInfo, Error> = .success(
        StorageInfo(totalBytes: 1000, freeBytes: 500, appUsedBytes: 100)
    )
    var recordingFilesResult: Result<[RecordingFile], Error> = .success([])
    var deleteFilesResult: Result<Int, Error> = .success(0)

    var fetchStorageInfoCallCount = 0
    var fetchRecordingFilesCallCount = 0
    var deleteFilesCallCount = 0
    var deleteFilesReceivedIds: [UUID] = []

    func fetchStorageInfo() async throws -> StorageInfo {
        fetchStorageInfoCallCount += 1
        switch storageInfoResult {
        case .success(let value): return value
        case .failure(let error): throw error
        }
    }

    func fetchRecordingFiles() async throws -> [RecordingFile] {
        fetchRecordingFilesCallCount += 1
        switch recordingFilesResult {
        case .success(let value): return value
        case .failure(let error): throw error
        }
    }

    func deleteFiles(ids: [UUID]) async throws -> Int {
        deleteFilesCallCount += 1
        deleteFilesReceivedIds = ids
        switch deleteFilesResult {
        case .success(let value): return value
        case .failure(let error): throw error
        }
    }
}
