import Core
import Foundation

/// 오디오-요약 유스케이스 프로토콜.
public protocol AudioToSummaryUseCase: Sendable {
    /// 오디오 파일을 분석하여 전사·키워드·요약 결과를 반환합니다.
    /// - Parameter audioFileURL: 분석할 오디오 파일의 URL
    /// - Returns: 전사, 키워드, 요약이 포함된 `AudioToSummaryResult`
    /// - Throws: `AudioToSummaryUseCaseError` (전사·요약 실패)
    func execute(audioFileURL: URL) async throws(AudioToSummaryUseCaseError) -> AudioToSummaryResult
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

    public func execute(audioFileURL: URL) async throws(AudioToSummaryUseCaseError)
        -> AudioToSummaryResult
    {
        do {
            try Task.checkCancellation()

            let transcript = try await sttRepository.transcribe(audioFileURL: audioFileURL)

            try Task.checkCancellation()

            let (keywords, summary) = try await summaryRepository.summarize(transcript: transcript)

            try Task.checkCancellation()

            return AudioToSummaryResult(
                transcript: transcript,
                keywords: keywords,
                summary: summary
            )
        } catch {
            AppLogger.error(error)
            throw AudioToSummaryUseCaseError(error)
        }
    }
}

fileprivate extension AudioToSummaryUseCaseError {
    init(_ error: Error) {
        if error is CancellationError {
            self = .cancelled
        } else if let error = error as? STTRepositoryError {
            switch error {
            case .cancelled:
                self = .cancelled
            case .unknown:
                self = .unknown(error)
            case .transcribeFailed:
                self = .transcribeFailed(error)
            }
        } else if let error = error as? SummaryRepositoryError {
            switch error {
            case .cancelled:
                self = .cancelled
            case .unknown:
                self = .unknown(error)
            case .summarizeFailed:
                self = .summarizeFailed(error)
            }
        } else {
            self = .unknown(error)
        }
    }
}
