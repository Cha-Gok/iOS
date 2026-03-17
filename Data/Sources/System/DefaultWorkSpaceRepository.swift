import Foundation
import Domain

/// 파일 시스템 내부 조작을 위한 내부 익스텐션 인터페이스.
internal protocol InternalWorkSpaceRepository: WorkSpaceRepository {

    /// 특정 URL에 디렉토리가 존재하는지 확인합니다.
    /// - Parameter url: 확인할 대상 경로
    /// - Returns: 폴더 존재 여부
    func directoryExists(at url: URL) -> Bool

}
