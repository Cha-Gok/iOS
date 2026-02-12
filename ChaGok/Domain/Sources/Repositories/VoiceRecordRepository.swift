import Foundation

/// 녹음(VoiceRecord) 엔티티의 CRUD를 담당하는 리포지토리 프로토콜.
/// 생성·목록 조회·기간별 필터·삭제 등 녹음 데이터 접근은 이 레포지토리를 통해 이루어집니다.
public protocol VoiceRecordRepository: Sendable {
    /// 새로운 녹음을 저장합니다.
    /// - Parameter recording: 저장할 녹음 엔티티
    /// - Returns: 저장된 녹음 엔티티
    /// - Throws: 저장 실패 시
    func save(_ recording: VoiceRecord) async throws -> VoiceRecord

    /// 모든 녹음 목록을 조회합니다.
    /// - Returns: 조회된 녹음 목록 (생성일 기준 내림차순)
    /// - Throws: 조회 실패 시
    func fetchAll() async throws -> [VoiceRecord]

    /// ID로 특정 녹음을 조회합니다.
    /// - Parameter id: 조회할 녹음의 ID
    /// - Returns: 조회된 녹음 엔티티 (없으면 nil)
    /// - Throws: 조회 실패 시
    func fetch(byId id: String) async throws -> VoiceRecord?

    /// 지정한 날짜보다 이전에 생성된 녹음 목록을 조회합니다.
    /// - Parameter date: 이 날짜보다 이전에 생성된 녹음이 대상입니다.
    /// - Returns: 조회된 녹음 목록
    /// - Throws: 조회 실패 시
    func fetchRecordings(olderThan date: Date) async throws -> [VoiceRecord]

    /// 기존 녹음을 업데이트합니다.
    /// - Parameter recording: 업데이트할 녹음 엔티티
    /// - Returns: 업데이트된 녹음 엔티티
    /// - Throws: 업데이트 실패 시
    func update(_ recording: VoiceRecord) async throws -> VoiceRecord

    /// ID로 특정 녹음을 삭제합니다.
    /// - Parameter id: 삭제할 녹음의 ID
    /// - Throws: 삭제 실패 시
    func delete(byId id: String) async throws

    /// 지정한 날짜보다 오래된 녹음을 삭제하고, 삭제된 개수를 반환합니다.
    /// - Parameter date: 이 날짜보다 오래된 녹음이 삭제 대상입니다.
    /// - Returns: 실제로 삭제된 녹음 개수
    /// - Throws: 삭제 중 오류 발생 시
    func deleteRecordings(olderThan date: Date) async throws -> Int
}
