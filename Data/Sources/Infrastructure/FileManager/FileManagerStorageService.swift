import Core
import Foundation

/// 파일 시스템 기반의 스토리지 서비스 구현체
public struct FileManagerStorageService: StorageService, @unchecked Sendable {
    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    public func generateTemporaryURL(fileName: String) throws(StorageServiceError) -> URL {
        AppLogger.debug("임시 URL 생성 시작: \(fileName)")

        if Task.isCancelled {
            AppLogger.debug("작업 취소됨: generateTemporaryURL")
            throw StorageServiceError.cancelled
        }

        let tempDirectory = fileManager.temporaryDirectory
        let directoryURL = tempDirectory.appendingPathComponent(UUID().uuidString)
        let fileURL = directoryURL.appendingPathComponent(fileName)

        do {
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
            AppLogger.debug("임시 디렉토리 생성 완료: \(directoryURL.path)")
            return fileURL
        } catch {
            AppLogger.error("임시 디렉토리 생성 실패: \(error)")
            throw StorageServiceError.uncreatableTemporaryPath
        }
    }

    public func moveFile(
        from sourceURL: URL,
        toDirectory directory: String,
        fileName: String
    ) throws(StorageServiceError) -> String {
        AppLogger.debug("파일 이동 시작: \(sourceURL.lastPathComponent) -> \(directory)/\(fileName)")

        if Task.isCancelled {
            AppLogger.debug("작업 취소됨: moveFile")
            throw StorageServiceError.cancelled
        }

        guard fileManager.fileExists(atPath: sourceURL.path) else {
            AppLogger.error("원본 파일을 찾을 수 없음: \(sourceURL.path)")
            throw StorageServiceError.fileNotFound
        }

        guard let documentURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            AppLogger.error("Document 디렉토리를 찾을 수 없음")
            throw StorageServiceError.moveFailed
        }

        let directoryURL = documentURL.appendingPathComponent(directory)
        let destinationURL = directoryURL.appendingPathComponent(fileName)

        do {
            if !fileManager.fileExists(atPath: directoryURL.path) {
                try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
                AppLogger.debug("디렉토리 생성됨: \(directoryURL.path)")
            }

            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
                AppLogger.debug("기존 파일 삭제됨 (덮어쓰기): \(destinationURL.path)")
            }

            if Task.isCancelled {
                AppLogger.debug("작업 취소됨: moveFile (이동 전)")
                throw StorageServiceError.cancelled
            }

            try fileManager.moveItem(at: sourceURL, to: destinationURL)
            AppLogger.info("파일 이동 성공: \(destinationURL.path)")
            return "\(directory)/\(fileName)"
        } catch {
            AppLogger.error("파일 이동 실패: \(error)")
            throw StorageServiceError.moveFailed
        }
    }

    public func save(
        data: Data,
        toDirectory directory: String,
        fileName: String
    ) throws(StorageServiceError) -> String {
        AppLogger.debug("파일 저장 시작: \(directory)/\(fileName) (size: \(data.count) bytes)")

        if Task.isCancelled {
            AppLogger.debug("작업 취소됨: save")
            throw StorageServiceError.cancelled
        }

        guard let documentURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            AppLogger.error("Document 디렉토리를 찾을 수 없음")
            throw StorageServiceError.writeFailed
        }

        let directoryURL = documentURL.appendingPathComponent(directory)
        let fileURL = directoryURL.appendingPathComponent(fileName)

        do {
            if !fileManager.fileExists(atPath: directoryURL.path) {
                try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
                AppLogger.debug("디렉토리 생성됨: \(directoryURL.path)")
            }

            if Task.isCancelled {
                AppLogger.debug("작업 취소됨: save (쓰기 전)")
                throw StorageServiceError.cancelled
            }

            try data.write(to: fileURL, options: .atomic)
            AppLogger.info("파일 저장 성공: \(fileURL.path)")
            return "\(directory)/\(fileName)"
        } catch {
            AppLogger.error("파일 저장 실패: \(error)")
            throw StorageServiceError.writeFailed
        }
    }

    public func load(relativePath: String) throws(StorageServiceError) -> Data {
        let absoluteURL = absoluteURL(for: relativePath)
        AppLogger.debug("파일 로드 시작: \(absoluteURL.path)")

        if Task.isCancelled {
            AppLogger.debug("작업 취소됨: load")
            throw StorageServiceError.cancelled
        }

        guard fileManager.fileExists(atPath: absoluteURL.path) else {
            AppLogger.error("파일을 찾을 수 없음: \(absoluteURL.path)")
            throw StorageServiceError.fileNotFound
        }

        do {
            let data = try Data(contentsOf: absoluteURL)
            AppLogger.debug("파일 로드 성공: \(absoluteURL.path) (\(data.count) bytes)")
            return data
        } catch {
            AppLogger.error("파일 로드 실패: \(error)")
            throw StorageServiceError.readFailed
        }
    }

    public func delete(fileURL: URL) throws(StorageServiceError) {
        AppLogger.debug("임시 파일 삭제 시작: \(fileURL.path)")

        if Task.isCancelled {
            AppLogger.debug("작업 취소됨: delete")
            throw StorageServiceError.cancelled
        }

        guard fileManager.fileExists(atPath: fileURL.path) else {
            AppLogger.error("삭제할 파일을 찾을 수 없음: \(fileURL.path)")
            throw StorageServiceError.fileNotFound
        }

        do {
            try fileManager.removeItem(at: fileURL)
            AppLogger.info("임시 파일 삭제 성공: \(fileURL.path)")
        } catch {
            AppLogger.error("임시 파일 삭제 실패: \(error)")
            throw StorageServiceError.deleteFailed
        }
    }

    public func exists(relativePath: String) -> Bool {
        let absoluteURL = absoluteURL(for: relativePath)
        let isExists = fileManager.fileExists(atPath: absoluteURL.path)
        AppLogger.debug("파일 존재 확인 (\(isExists)): \(absoluteURL.path)")
        return isExists
    }

    public func absoluteURL(for relativePath: String) -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(relativePath)
    }
}
