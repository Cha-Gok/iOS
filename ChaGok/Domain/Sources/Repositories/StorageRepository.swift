import Foundation

/// 저장소(스토리지) 및 녹음 파일 조회·삭제를 담당하는 리포지토리 프로토콜.
public protocol StorageRepository: Sendable {
    /// 저장소 용량 정보를 조회합니다.
    /// - Returns: 앱·디바이스 저장 공간 정보 (`StorageInfo`)
    /// - Throws: 저장소 접근 실패 시
    func fetchStorageInfo() async throws -> StorageInfo

    /// 녹음 파일 목록을 조회합니다.
    /// - Returns: 녹음 파일 엔티티 목록 (생성일 등 정렬 방식은 구현체에 따름)
    /// - Throws: 파일 목록 조회 실패 시
    func fetchRecordingFiles() async throws -> [VoiceRecord]

    /// 지정한 날짜에 해당하는 녹음 파일을 삭제하고, 삭제된 파일 개수를 반환합니다.
    /// - Parameter date: 삭제할 파일의 기준 날짜 (예: 해당 날짜에 생성된 파일만 삭제)
    /// - Returns: 실제로 삭제된 파일 개수
    /// - Throws: 삭제 중 오류 발생 시
    func deleteFiles(date: Date) async throws -> Int
}
