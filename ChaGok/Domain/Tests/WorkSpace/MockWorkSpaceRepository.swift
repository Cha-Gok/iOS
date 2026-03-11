import Foundation
import Domain

struct MockWorkSpaceRepository: WorkSpaceRepository {

    enum RootURLBehavior: Sendable {
        case success(URL)       // 성공한 경우
        case cancelled          // 작업 취소의 경우
        case unknown(Error)     // 알수 없는 오류
    }

    enum BasicFolderBehavior: Sendable {
        case success(Folder)    // 성공한 경우
        case cancelled          // 작업 취소 경우
        case notFound           // 기본 폴더를 찾을 수 없는 경우
        case createFailed       // 기본 폴더 Entity 생성 실패의 경우
        case unknown(Error)     // 알수 없는 오류
    }

    var rootUrlBehavior: RootURLBehavior?
    var basicFolderBehavior: BasicFolderBehavior?
    var rootUrlDelay: UInt64 = 0

    typealias RootURLError = Domain.WorkSpaceRootURLRepositoryError
    typealias BasicFolderError = Domain.WorkSpaceBasicFolderRepositoryError

    init(
        rootUrlBehavior: RootURLBehavior? = nil,
        basicFolderBehavior: BasicFolderBehavior? = nil,
        rootUrlDelay: UInt64 = 0
    ) {
        self.rootUrlBehavior = rootUrlBehavior
        self.basicFolderBehavior = basicFolderBehavior
        self.rootUrlDelay = rootUrlDelay
    }

    func fetchRootURL() async throws(RootURLError) -> URL {
        if rootUrlDelay > 0 {
            try? await Task.sleep(nanoseconds: rootUrlDelay)
        }

        if Task.isCancelled {
            throw RootURLError.cancelled
        }

        switch rootUrlBehavior {
            case .success(let url):
                return url
            case .cancelled:
                throw RootURLError.cancelled
            case .unknown(let error):
                throw RootURLError.unknown(error)
            case .none:
                fatalError("RootURLBehavior가 없습니다.")
        }
    }

    func fetchOrCreateBasicFolder() async throws(BasicFolderError) -> Domain.Folder {
        if rootUrlDelay > 0 {
            try? await Task.sleep(nanoseconds: rootUrlDelay)
        }

        if Task.isCancelled {
            throw BasicFolderError.cancelled
        }

        switch basicFolderBehavior {
            case .success(let folder):
                return folder
            case .cancelled:
                throw BasicFolderError.cancelled
            case .notFound:
                throw BasicFolderError.notFound
            case .createFailed:
                throw BasicFolderError.createFailed
            case .unknown(let error):
                throw BasicFolderError.unknown(error)
            case .none:
                fatalError("BasicFolderBehavior가 없습니다.")
        }
    }

}
