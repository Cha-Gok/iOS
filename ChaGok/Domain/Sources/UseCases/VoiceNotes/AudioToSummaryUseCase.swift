import Foundation

/// 오디오-요약 유스케이스 프로토콜.
public protocol AudioToSummaryUseCase: Sendable {
    /// 오디오 파일을 분석하여 전사·키워드·요약 결과를 반환합니다.
    /// - Parameter audioFileURL: 분석할 오디오 파일의 URL
    /// - Returns: 전사, 키워드, 요약이 포함된 `AudioToSummaryResult`
    /// - Throws: 전사·키워드 추출·요약 중 하나라도 실패 시
    func execute(audioFileURL: URL) async throws -> AudioToSummaryResult
}

public struct DefaultAudioToSummaryUseCase: AudioToSummaryUseCase {

    private let sttRepository: STTRepository
    private let summaryRepository: SummaryRepository

    public init(
        sttRepository: STTRepository,
        summaryRepository: SummaryRepository
    ) {
        self.sttRepository = sttRepository
        self.summaryRepository = summaryRepository
    }

    public func execute(audioFileURL: URL) async throws -> AudioToSummaryResult {
        // 1. 오디오 파일 전사
        let transcript = try await sttRepository.transcribe(audioFileURL: audioFileURL)

        // 2. 키워드 추출 및 요약
        let (keywords, summary) = try await summaryRepository.summarize(transcript: transcript)

        return AudioToSummaryResult(
            transcript: transcript,
            keywords: keywords,
            summary: summary
        )
    }
}
