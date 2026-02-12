import Foundation
import Core

public protocol FolderSystemDataSource {
    /// 앱에서 사용하는 최상위 Root 폴더 이름
    static var rootName: String { get }
    /// 앱 전용 Root 폴더 경로
    var rootDirectory: URL { get }
}

extension FolderSystemDataSource {
    public static var rootName: String { "ChaGokTemp" }
}

protocol FolderSystemInternalDataSource: FolderSystemDataSource {
    /// Root 폴더 생성  - 디랙터리가 없다면 폴더를 생성합니다.
    func createRootDirectoryIfNeeded(url: URL) throws
    /// 디렉터리 존재 여부 확인
    func directoryExists(url: URL) -> Bool
}

/// 앱 전용 파일 시스템의 Root 디렉터리를 관리하는 객체
public final class DefaultFolderManager: FolderSystemInternalDataSource {
    private let fileManager: FileManager
    public let rootDirectory: URL
    let baseURL: URL

    public init(
        fileManager: FileManager = .default,
        baseURL: URL? = nil
    ) {
        self.fileManager = fileManager
        guard let rootPath = baseURL ?? fileManager.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
        ).first else {
            fatalError("Application Support Directory를 찾을 수 없습니다.")
        }

        let dir = rootPath.appending(
            path: Self.rootName,
            directoryHint: .isDirectory
        )

        self.baseURL = rootPath
        self.rootDirectory = dir
        try? createRootDirectoryIfNeeded(url: self.rootDirectory)
    }

    func directoryExists(url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        let exists = fileManager.fileExists(
            atPath: url.path,
            isDirectory: &isDirectory
        )
        return exists && isDirectory.boolValue
    }

    func createRootDirectoryIfNeeded(url: URL) throws {
        guard !directoryExists(url: url) else { return }

        do {
            try fileManager.createDirectory(
                at: url,
                withIntermediateDirectories: true,
                attributes: nil
            )
        } catch {
            AppLogger.debug("ChaGokTemp 폴더 생성 실패: \(error)")
        }
    }
}
