import Foundation

public enum CoreDataStorageError: Error, Sendable {
    case resourceNotFound
    case initializeFailed
    case unknown(any Error)
}
