import Core
import Foundation

/// 음성 메모 통합 유스케이스 프로토콜.
public protocol VoiceNoteUseCase: Sendable {
    /// 새로운 음성 메모를 생성합니다.
    func create(_ voiceRecord: VoiceRecord) async throws(VoiceNoteUseCaseError) -> VoiceNote

    /// 기본 폴더의 모든 음성 메모를 조회합니다.
    func fetchAllFromDefaultFolder() async throws(VoiceNoteUseCaseError) -> [VoiceNote]

    /// 특정 폴더의 모든 음성 메모를 조회합니다.
    func fetchAll(folderID: UUID) async throws(VoiceNoteUseCaseError) -> [VoiceNote]

    /// 특정 음성 메모를 조회합니다.
    func fetch(byId id: UUID) async throws(VoiceNoteUseCaseError) -> VoiceNote

    /// 최근 생성된 음성 메모를 조회합니다.
    func fetchRecent(limit: Int) async throws(VoiceNoteUseCaseError) -> [VoiceNote]

    /// 음성 메모 정보를 업데이트합니다.
    func update(_ voiceNote: VoiceNote) async throws(VoiceNoteUseCaseError) -> VoiceNote

    /// 오디오 파일을 분석하여 전사·키워드·요약 결과를 반환합니다.
    func summarize(audioFilePath: String, language: Language) async throws(VoiceNoteUseCaseError)
        -> AudioToSummaryResult
}
