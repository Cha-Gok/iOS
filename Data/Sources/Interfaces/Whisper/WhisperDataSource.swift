import Foundation
import WhisperKit

/// Whisper STT 모델 엔진을 제어하고 음성 전사 데이터를 제공하는 데이터 소스 인터페이스.
public protocol WhisperDataSource: Sendable {
    /// 모델의 다운로드 경로를 전달합니다.
    func getDownloadPath() async throws(WhisperDataSourceError) -> URL
    
    /// 다운로드
    func download(progressHandler: @Sendable @escaping (Progress) -> Void) async throws
    
    /// 캐싱된 Whisper 모델 인스턴스를 메모리에서 해제하여 자원을 반환합니다.
    func clearCache() async

    /// 백그라운드에서 모델을 미리 로드하여 최초 음성 전사 속도를 향상시킵니다.
    func preload() async

    /// 다운로드된 모델을 메모리에 로드합니다.
    func loadModel() async throws(WhisperDataSourceError)
    
    /// STT 전사 transcribe
    func transcribe(audioPath: URL) async throws -> [TranscriptionResult]
    
    /// DecodingOptions를 전달합니다 (`Getter`)
    func getDocodingOptions() async -> DecodingOptions
}
