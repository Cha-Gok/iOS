import Domain

extension VoiceNoteFetchRepositoryError {
    init(_ error: CoreDataStorageError) {
        switch error {
        case .fetchFailed:
            self = .unknown(error)
        case .fetchAllFailed:
            self = .unknown(error)
        default:
            self = .unknown(error)
        }
    }
}
