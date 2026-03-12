import Foundation
@testable import Domain

actor MockFolderRepository: FolderRepository {

    enum Behavior<T: Sendable>: Sendable {
        case success(T)         // 성공한 경우
        case cancelled          // 작업 취소의 경우
        case notFound           // 폴더를 찾을 수 없는 경우
        case duplicateName      // 이름이 중복된 경우
        case createFailed       // 생성에 실패한 경우
        case fetchFailed        // 조회에 실패한 경우
        case updateFailed       // 수정에 실패한 경우
        case unknown(Error)     // 알 수 없는 오류의 경우
    }

    var createBehavior: Behavior<Folder>?
    var fetchAllBehavior: Behavior<[Folder]>?
    var updateBehavior: Behavior<Folder>?

    var delay: UInt64 = 0

    init(
        createBehavior: Behavior<Folder>? = nil,
        fetchAllBehavior: Behavior<[Folder]>? = nil,
        updateBehavior: Behavior<Folder>? = nil,
        delay: UInt64 = 0
    ) {
        self.createBehavior = createBehavior
        self.fetchAllBehavior = fetchAllBehavior
        self.updateBehavior = updateBehavior
        self.delay = delay
    }

    func create(name: String) async throws(FolderRepositoryError) -> Folder {
        try await handleBehavior(createBehavior, methodName: "create")
    }

    func fetchAll() async throws(FolderRepositoryError) -> [Folder] {
        try await handleBehavior(fetchAllBehavior, methodName: "fetchAll")
    }

    func update(_ folder: Folder) async throws(FolderRepositoryError) -> Folder {
        try await handleBehavior(updateBehavior, methodName: "update")
    }
}

// MARK: - Helper Function

extension MockFolderRepository {
    private func handleBehavior<T>(
        _ behavior: Behavior<T>?,
        methodName: String
    ) async throws(FolderRepositoryError) -> T {
        if delay > 0 {
            try? await Task.sleep(nanoseconds: delay)
        }

        if Task.isCancelled {
            throw .cancelled
        }

        guard let behavior = behavior else {
            fatalError("\(methodName)의 Behavior가 설정되지 않았습니다.")
        }

        switch behavior {
            case .success(let value): return value
            case .cancelled: throw .cancelled
            case .notFound: throw .notFound
            case .duplicateName: throw .duplicateName
            case .createFailed: throw .createFailed
            case .fetchFailed: throw .fetchFailed
            case .updateFailed: throw .updateFailed
            case .unknown(let error): throw .unknown(error)
        }
    }
}
