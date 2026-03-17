import Foundation

/// 저장 공간 정보 조회 유스케이스 프로토콜.
public protocol FetchStorageInfoUseCase: Sendable {
    /// 저장 공간 정보를 조회합니다.
    /// - Returns: 앱·디바이스 저장 공간 정보 (`StorageInfo`)
    /// - Throws: 저장소 접근 실패 시
    func execute() async throws -> StorageInfo
}

public struct DefaultFetchStorageInfoUseCase: FetchStorageInfoUseCase {
    private let storageRepository: StorageRepository

    public init(storageRepository: StorageRepository) {
        self.storageRepository = storageRepository
    }

    public func execute() async throws -> StorageInfo {
        try await storageRepository.fetchStorageInfo()
    }
}
