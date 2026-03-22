import Foundation

/// 파일 시스템 접근 및 조작을 위한 인터페이스입니다.
public protocol FileService {
    /// 지정된 검색 경로 디렉토리에 대한 URL 배열을 반환합니다.
    /// - Parameters:
    ///   - directory: 검색할 디렉토리 유형 (예: .documentDirectory)
    ///   - domainMask: 검색할 도메인 마스크 (예: .userDomainMask)
    /// - Returns: 검색된 URL 배열
    func urls(
        for directory: FileManager.SearchPathDirectory,
        in domainMask: FileManager.SearchPathDomainMask
    ) -> [URL]

    /// 지정된 경로에 파일이나 디렉토리가 존재하는지 확인합니다.
    /// - Parameter path: 확인할 파일 시스템 경로
    /// - Returns: 존재 여부
    func fileExists(atPath path: String) -> Bool

    /// 지정된 URL에 디렉토리를 생성합니다.
    /// - Parameters:
    ///   - url: 생성할 디렉토리의 URL
    ///   - createIntermediates: 중간 경로의 디렉토리가 없을 경우 함께 생성할지 여부
    ///   - attributes: 디렉토리에 적용할 속성 (선택 사항)
    /// - Throws: 디렉토리 생성 실패 시 발생하는 에러
    func createDirectory(
        at url: URL,
        withIntermediateDirectories createIntermediates: Bool,
        attributes: [FileAttributeKey: Any]?
    ) throws
}
