import Foundation

/// 저장소(스토리지) 및 녹음 파일 조회·삭제를 담당하는 리포지토리 프로토콜.
public protocol StorageRepository: Sendable {
    /// 저장소 용량 정보를 조회합니다.
    /// - Returns: 앱·디바이스 저장 공간 정보 (`StorageInfo`)
    /// - Throws: 저장소 접근 실패 시
    func fetchStorageInfo() async throws -> StorageInfo
}
