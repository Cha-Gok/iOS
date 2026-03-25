import Foundation

/// 스토리지 서비스 프로토콜
public protocol StorageService: Sendable {
    /// 작업을 위한 안전한 임시 파일 경로를 생성하여 반환합니다.
    /// - Parameter fileName: 생성할 임시 파일의 이름
    /// - Returns: 생성된 임시 파일의 URL
    /// - Throws: `StorageServiceError.uncreatableTemporaryPath`
    func generateTemporaryURL(fileName: String) async throws(StorageServiceError) -> URL

    /// 지정된 원본 파일을 새로운 디렉토리와 이름으로 이동시킵니다.
    /// - Parameters:
    ///   - sourceURL: 원본 파일이 위치한 URL
    ///   - directory: 최종 저장할 논리적 디렉토리 이름
    ///   - fileName: 저장할 최종 파일 이름
    /// - Returns: 이동이 완료된 최종 파일의 URL
    /// - Throws: `StorageServiceError.moveFailed`
    func moveFile(
        from sourceURL: URL,
        toDirectory directory: String,
        fileName: String
    ) async throws(StorageServiceError) -> URL

    /// 메모리 상의 Data를 특정 디렉토리에 파일로 저장합니다.
    /// - Parameters:
    ///   - data: 저장할 데이터
    ///   - directory: 저장할 디렉토리 이름
    ///   - fileName: 저장할 파일 이름
    /// - Returns: 저장된 파일의 URL
    /// - Throws: `StorageServiceError.writeFailed`
    func save(data: Data, toDirectory directory: String, fileName: String) async throws(StorageServiceError) -> URL

    /// 지정된 URL의 파일을 읽어 Data로 반환합니다.
    /// - Parameter fileURL: 읽어올 파일의 URL
    /// - Returns: 파일의 Data
    /// - Throws: `StorageServiceError.readFailed`
    func load(fileURL: URL) async throws(StorageServiceError) -> Data

    /// 지정된 URL의 파일을 시스템에서 영구 삭제합니다.
    /// - Parameter fileURL: 삭제할 파일의 URL
    /// - Throws: `StorageServiceError.deleteFailed`
    func delete(fileURL: URL) async throws(StorageServiceError)

    /// 지정된 URL에 파일이 존재하는지 확인합니다.
    /// - Parameter fileURL: 확인할 파일의 URL
    /// - Returns: 존재 여부
    func exists(fileURL: URL) async -> Bool
}
