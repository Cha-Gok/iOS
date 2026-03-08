import Foundation

/// 기본 폴더의의 존재 유무 판단 및 생성을 반환하는 유즈케이스
public protocol FetchBasicFolderUseCase: Sendable {
    /// 기본 폴더가 존재하는지 판단하고 반환합니다.
    /// - Parameter None
    /// - Returns: 생성된 기본 폴더
    /// - Throws: 기본 폴더 생성 실패 시
    @discardableResult
    func execute() async throws(FetchBasicFolderUseCaseError) -> Folder
}

public struct DefaultFetchBasicFolderUseCase: FetchBasicFolderUseCase {

    private let repository: WorkSpaceRepository

    public init(repository: WorkSpaceRepository) {
        self.repository = repository
    }

    @discardableResult
    public func execute() async throws(FetchBasicFolderUseCaseError) -> Folder {
        typealias UseCaseError = FetchBasicFolderUseCaseError
        if Task.isCancelled { throw FetchBasicFolderUseCaseError.cancelled }
        do {
            // 기본 폴더 생성/확인
            return try await repository.fetchOrCreateBasicFolder()
        } catch let error {
            switch error {
                case .cancelled:
                    throw UseCaseError.cancelled
                case .createFailed:
                    throw UseCaseError.createFailed
                case .notFound:
                    throw UseCaseError.notFound
                case .unknown(let error):
                    throw UseCaseError.unknown(error)
            }
        }
    }
}
