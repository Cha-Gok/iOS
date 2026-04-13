import Domain
import Foundation

/// 음성 파일 전사(Speech-to-Text) 서비스 프로토콜
public protocol STTService: Sendable {
    /// 현재 음성 인식 권한 상태를 확인합니다.
    /// - Returns: 현재 음성 인식 권한 상태
    func checkPermission() async -> PermissionStatus

    /// 사용자에게 음성 인식 권한을 요청합니다.
    /// - Returns: 권한 요청 후 음성 인식 권한 상태
    func requestPermission() async -> PermissionStatus

    /// 오디오 파일을 전사합니다.
    /// - Parameter audioFileURL: 전사할 오디오 파일 URL
    /// - Returns: 전사된 텍스트 및 세그먼트 타이밍 정보
    /// - Throws: `STTServiceError`
    func transcribe(audioFileURL: URL) async throws(STTServiceError) -> STTResult
}
