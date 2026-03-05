import Foundation

/// 음성 인식(Speech-to-Text)을 담당하는 리포지토리 프로토콜.
public protocol STTRepository: Sendable {
    /// 오디오 파일을 전사(Transcription)합니다.
    /// - Parameter audioFileURL: 전사할 오디오 파일의 URL
    /// - Returns: 전사된 텍스트 엔티티
    /// - Throws: 전사 실패 시
    func transcribe(audioFileURL: URL) async throws -> Transcript
}
