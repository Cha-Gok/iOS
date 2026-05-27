import Foundation
import WhisperKit

/// Whisper STT 모델 엔진을 제어하고 음성 전사 데이터를 제공하는 데이터 소스 인터페이스.
@MainActor
public protocol WhisperDataSource {
    /// 모델의 다운로드 경로를 전달합니다.
    func getDownloadPath() async throws(WhisperDataSourceError) -> URL
    
    /// 다운로드
    func download(progressHandler: @Sendable @escaping (Progress) -> Void) async throws

    /// Whisper 객체를 반환합니다.
    /// 이미 다운로드 한 경우 preload하기 위한 prewarmModels
    func getWhisper() async throws(WhisperDataSourceError) -> WhisperKit
    
    /// 캐싱된 Whisper 모델 인스턴스를 메모리에서 해제하여 자원을 반환합니다.
    func clearCache() async

    /// 백그라운드에서 모델을 미리 로드하여 최초 음성 전사 속도를 향상시킵니다.
    func preload() async
    
    /// DecodingOptions를 전달합니다 (`Getter`)
    func getDocodingOptions() -> DecodingOptions
}
