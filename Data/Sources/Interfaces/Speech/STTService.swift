import Foundation

/// 음성 파일 전사(Speech-to-Text) 서비스 프로토콜
public protocol STTService: Sendable {
    /// 오디오 파일을 전사합니다.
    /// - Parameter audioFileURL: 전사할 오디오 파일 URL
    /// - Returns: 전사된 텍스트
    /// - Throws: `STTServiceError`
    func transcribe(audioFileURL: URL) async throws(STTServiceError) -> String
}
