import Foundation

public enum CoreDataStorageError: Error, Sendable {
    case resourceNotFound
    case initializeFailed
    case unknown(any Error)
    case createFailed
    case fetchFailed
    case updateFailed
    case deleteFailed
}
