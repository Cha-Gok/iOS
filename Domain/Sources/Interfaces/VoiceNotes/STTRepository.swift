import Foundation

/// 음성 인식(Speech-to-Text) 및 STT 권한을 담당하는 리포지토리 프로토콜.
public protocol STTRepository: Sendable {
    /// 오디오 파일을 전사(Transcription)합니다.
    /// - Parameter audioFilePath: 전사할 오디오 파일의 상대 경로 (예: `"VoiceRecords/file.m4a"`)
    /// - Returns: 전사된 텍스트 엔티티
    /// - Throws: `STTRepositoryError` (전사 실패)
    func transcribe(audioFilePath: String) async throws(STTRepositoryError) -> Transcript

    /// STT 권한이 허용되어 있는지 확인합니다.
    /// - Returns: 현재 STT 권한 상태.
    func checkSTTPermission() -> PermissionStatus

    /// STT 권한을 요청합니다.
    /// - Returns: 요청 결과 권한 상태.
    /// - Throws: `STTPermissionRepositoryError`
    func requestSTTPermission() async throws(STTPermissionRepositoryError) -> PermissionStatus

    /// 온디바이스 모델 다운로드를 진행합니다.
    /// Speech 프레임워크를 사용할 경우 함수를 호출하지 않으며, Whisper 또는 다른 HuggingFace 모델 다운로드 용도로 사용합니다.
    /// - Returns: 모델 다운로드 경로
    /// - Throws: `STTRepositoryError`
    @discardableResult
    func download(progressHandler: (@Sendable (Progress) -> Void)?) async throws(STTRepositoryError) -> URL
}

public extension STTRepository {
    @discardableResult
    func download(
        progressHandler: (@Sendable (Progress) -> Void)? = nil
    ) async throws(STTRepositoryError) -> URL {
        throw .downloadFailed
    }
}
