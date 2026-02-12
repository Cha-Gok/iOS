import Foundation

/// 삭제 대상 녹음을 필터링하고, 레포지토리에 삭제를 요청하는 유스케이스.
public protocol DeleteRecordingsUseCase: Sendable {
    /// 지정한 날짜보다 오래된 녹음을 삭제하고, 삭제된 개수를 반환합니다.
    /// - Parameter date: 이 날짜보다 이전에 생성된 녹음이 삭제됩니다.
    /// - Returns: 실제로 삭제된 녹음 개수
    /// - Throws: 삭제 중 오류 발생 시
    func deleteRecordings(olderThan date: Date) async throws -> Int

    /// ID로 특정 녹음을 삭제합니다.
    /// - Parameter id: 삭제할 녹음의 ID
    /// - Throws: 삭제 실패 시
    func deleteRecording(byId id: String) async throws
}

public struct DefaultDeleteRecordingsUseCase: DeleteRecordingsUseCase {
    private let voiceRecordRepository: VoiceRecordRepository

    public init(voiceRecordRepository: VoiceRecordRepository) {
        self.voiceRecordRepository = voiceRecordRepository
    }

    public func deleteRecordings(olderThan date: Date) async throws -> Int {
        try await voiceRecordRepository.deleteRecordings(olderThan: date)
    }

    public func deleteRecording(byId id: String) async throws {
        try await voiceRecordRepository.delete(byId: id)
    }
}
