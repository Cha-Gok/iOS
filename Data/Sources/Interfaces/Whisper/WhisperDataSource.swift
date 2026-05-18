import Foundation
import WhisperKit

/// Whisper STT 모델 엔진을 제어하고 음성 전사 데이터를 제공하는 데이터 소스 인터페이스.
public protocol WhisperDataSource: Sendable {
    /// 모델 파일이 저장되는 기기 내부의 로컬 기본 디렉토리 URL.
    var downloadedBaseURL: URL { get async }

    /// 지정된 오디오 파일 경로의 음성 데이터를 텍스트로 변환(전사)합니다.
    /// - Parameter audioFilePath: 전사할 오디오 파일의 로컬 상대 경로
    /// - Returns: 변환 결과인 `TranscriptionResult` 배열
    func transcribe(audioFilePath: String) async throws -> [TranscriptionResult]

    /// 캐싱된 Whisper 모델 인스턴스를 메모리에서 해제하여 자원을 반환합니다.
    func clearCache() async

    /// 백그라운드에서 모델을 미리 로드하여 최초 음성 전사 속도를 향상시킵니다.
    func preload() async
}
