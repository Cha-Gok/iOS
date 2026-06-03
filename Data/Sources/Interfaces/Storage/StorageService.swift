import Foundation

/// 스토리지 서비스 프로토콜
///
/// - 임시 파일 (녹음 중): `URL` 기반 — 절대 경로로 즉시 접근 필요
/// - 영구 파일 (Documents 저장): `String` 경로 기반 — 앱 컨테이너 변경에 안전한 상대 경로
public protocol StorageService: Sendable {
    /// 녹음 작업을 위한 임시 파일 URL을 생성합니다.
    /// - Parameter fileName: 생성할 임시 파일의 이름
    /// - Returns: 생성된 임시 파일의 절대 URL
    /// - Throws: `StorageServiceError.uncreatableTemporaryPath`
    func generateTemporaryURL(fileName: String) throws(StorageServiceError) -> URL

    /// 임시 파일을 Documents 하위 디렉토리로 이동합니다.
    /// - Parameters:
    ///   - sourceURL: 이동할 임시 파일의 절대 URL
    ///   - directory: 저장할 디렉토리 이름
    ///   - fileName: 저장할 파일 이름
    /// - Returns: Documents 기준 상대 경로 (예: `"VoiceRecords/file.m4a"`)
    /// - Throws: `StorageServiceError.moveFailed`
    func moveFile(
        from sourceURL: URL,
        toDirectory directory: String,
        fileName: String
    ) throws(StorageServiceError) -> String

    /// 데이터를 Documents 하위 디렉토리에 파일로 저장합니다.
    /// - Parameters:
    ///   - data: 저장할 데이터
    ///   - directory: 저장할 디렉토리 이름
    ///   - fileName: 저장할 파일 이름
    /// - Returns: Documents 기준 상대 경로 (예: `"Images/file.png"`)
    /// - Throws: `StorageServiceError.writeFailed`
    func save(data: Data, toDirectory directory: String, fileName: String) throws(StorageServiceError) -> String

    /// 영구 저장 파일을 읽어 Data로 반환합니다.
    /// - Parameter relativePath: Documents 기준 상대 경로 (예: `"VoiceRecords/file.m4a"`)
    /// - Returns: 파일의 Data
    /// - Throws: `StorageServiceError.readFailed`
    func load(relativePath: String) throws(StorageServiceError) -> Data

    /// 임시 파일을 삭제합니다.
    /// - Parameter fileURL: 삭제할 임시 파일의 절대 URL
    /// - Throws: `StorageServiceError.deleteFailed`
    func delete(fileURL: URL) throws(StorageServiceError)

    /// 영구 저장 파일의 존재 여부를 확인합니다.
    /// - Parameter relativePath: Documents 기준 상대 경로 (예: `"VoiceRecords/file.m4a"`)
    /// - Returns: 파일 존재 여부
    func exists(relativePath: String) -> Bool

    /// 상대 경로를 현재 Documents 디렉토리 기준 절대 URL로 변환합니다.
    /// - Parameter relativePath: Documents 기준 상대 경로 (예: `"VoiceRecords/file.m4a"`)
    /// - Returns: 파일 시스템에서 실제로 접근 가능한 절대 URL
    func absoluteURL(for relativePath: String) -> URL
}
