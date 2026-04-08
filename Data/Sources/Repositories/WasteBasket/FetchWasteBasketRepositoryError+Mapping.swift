import Domain

extension FetchWasteBasketRepositoryError {
    init(_ error: CoreDataStorageError) {
        switch error {
        default:
            self = .fetchFailed
        }
    }
}
