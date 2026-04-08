import Domain

extension FetchWasteBasketRepositoryError {
    init(_ error: any Error) {
        self = .fetchFailed
    }
}
