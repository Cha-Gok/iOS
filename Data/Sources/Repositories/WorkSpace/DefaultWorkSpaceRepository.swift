import Domain
import Foundation

public actor DefaultWorkSpaceRepository: WorkSpaceRepository {
    private let fileService: FileService

    public init(fileService: FileService) {
        self.fileService = fileService
    }

    private func directoryExists(at url: URL) -> Bool {
        fileService.fileExists(atPath: url.path)
    }

    public func fetchRootURL() async throws(WorkSpaceRootURLRepositoryError) -> URL {
        if Task.isCancelled { throw .cancelled }
        guard let documentURL = fileService.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask).first
        else {
            throw .unknown(
                NSError(
                    domain: "WorkSpaceRepository",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "applicationSupportDirectory not found"]
                )
            )
        }
        return documentURL.appendingPathComponent(Policy.rootName, isDirectory: true)
    }

    public func fetchOrCreateBasicFolder() async throws(WorkSpaceBasicFolderRepositoryError) -> Folder {
        let rootURL: URL
        if Task.isCancelled { throw .cancelled }

        do {
            rootURL = try await fetchRootURL()
        } catch {
            if case .cancelled = error { throw .cancelled }
            throw .unknown(error)
        }

        if !directoryExists(at: rootURL) {
            do {
                try fileService.createDirectory(at: rootURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                throw .createFailed
            }
        }

        return Folder(
            path: rootURL,
            name: rootURL.lastPathComponent,
            isDeletable: false
        )
    }
}
