import Domain

public struct DefaultSTTPermissionRepository: STTPermissionRepository {
    private let service: any STTPermissionService

    public init(service: any STTPermissionService) {
        self.service = service
    }

    public func checkSTTPermission() async throws(STTPermissionRepositoryError) -> PermissionStatus {
        if Task.isCancelled { throw .cancelled }
        return await service.checkPermission()
    }

    public func requestSTTPermission() async throws(STTPermissionRepositoryError) -> PermissionStatus {
        if Task.isCancelled { throw .cancelled }
        return await service.requestPermission()
    }
}
