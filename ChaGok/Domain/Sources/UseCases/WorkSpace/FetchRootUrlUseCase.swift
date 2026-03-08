import Foundation

/// Root 폴더의 URL을 반환하는 유즈케이스
public protocol FetchRootUrlUseCase: Sendable {
    /// 루트 URL을 반환 합니다.
    /// - Parameter None
    /// - Returns: 생성된 루트 디렉토리 URL
    /// - Throws: 루트 폴더 생성 실패 시
    func execute() async throws(FetchRootUrlUseCaseError) -> URL
}

public struct DefaultFetchRootUrlUseCase: FetchRootUrlUseCase {

    private let repository: WorkSpaceRepository

    public init(repository: WorkSpaceRepository) {
        self.repository = repository
    }

    public func execute() async throws(FetchRootUrlUseCaseError) -> URL {
        typealias UseCaseError = FetchRootUrlUseCaseError
        if Task.isCancelled { throw FetchRootUrlUseCaseError.cancelled }
        do {
            // root URL 가져오기
            return try await repository.fetchRootURL()
        } catch {
            switch error {
                case .cancelled:
                    throw UseCaseError.cancelled
                case .unknown(let error):
                    throw UseCaseError.unknown(error)
            }
        }
    }
}
