import Foundation
import Domain
import CoreData

public struct DefaultFolderRepository: FolderRepository {

    private let controller: PersistenceController
    private let store: FolderCoreDataStore

    public init(controller: PersistenceController) {
        self.controller = controller
        self.store = .init(container: controller.container)
    }

    public func create(name: String) async throws -> Domain.Folder {

        let result = try await store.create(name)
        try controller.saveContext()

        return result
    }

    public func fetchAll() async throws -> [Domain.Folder] {

        let result = try await store.fetchAll()

        return result
    }

    public func update(_ folder: Domain.Folder) async throws -> Domain.Folder {
        // 해당 entity 속성 수정
        let result = try await store.update(with: folder)

        try controller.saveContext()

        return result
    }

    public func delete(byId id: UUID) async throws {
        try await store.delete(byId: id)

        try controller.saveContext()
    }

}
