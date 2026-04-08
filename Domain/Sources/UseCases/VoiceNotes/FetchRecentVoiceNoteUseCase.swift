import Core
import Foundation

/// 최근 기록 VoiceNote 조회 유스케이스 프로토콜.
public protocol FetchRecentVoiceNoteUseCase: Sendable {
    /// 전체 폴더에서 최근 생성된 VoiceNote를 조회합니다. (Policy.recentVoiceNoteLimit개 제한)
    /// - Returns: 최근 생성된 `VoiceNote` 배열
    /// - Throws: `FetchRecentVoiceNoteUseCaseError`
    func execute() async throws(FetchRecentVoiceNoteUseCaseError) -> [VoiceNote]
}

public struct DefaultFetchRecentVoiceNoteUseCase: FetchRecentVoiceNoteUseCase {
    private let repository: any VoiceNoteFetchRepository

    public init(repository: any VoiceNoteFetchRepository) {
        self.repository = repository
    }

    public func execute() async throws(FetchRecentVoiceNoteUseCaseError) -> [VoiceNote] {
        if Task.isCancelled { throw .cancelled }
        do {
            return try await repository.fetchRecent(limit: Policy.recentVoiceNoteLimit)
        } catch {
            AppLogger.error(error)
            throw FetchRecentVoiceNoteUseCaseError(error)
        }
    }
}
