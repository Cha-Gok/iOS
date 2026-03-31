import Domain

extension SummaryRepositoryError {
    init(_ error: SummaryServiceError) {
        switch error {
        case .cancelled:
            self = .cancelled
        case .modelUnavailable,
             .unsupportedLanguage,
             .rateLimited,
             .invalidResponse,
             .summarizeFailed:
            self = .summarizeFailed
        case .unknown(let error):
            self = .unknown(error)
        }
    }
}
