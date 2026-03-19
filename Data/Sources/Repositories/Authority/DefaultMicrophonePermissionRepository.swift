import Domain

public struct DefaultMicrophonePermissionRepository: MicrophonePermissionRepository {
    private let service: any MicrophonePermissionService

    public init(service: any MicrophonePermissionService) {
        self.service = service
    }

    public func checkMicrophonePermission() async throws(MicrophonePermissionRepositoryError) -> PermissionStatus {
        if Task.isCancelled { throw .cancelled }
        return await service.checkPermission()
    }

    public func requestMicrophonePermission() async throws(MicrophonePermissionRepositoryError) -> PermissionStatus {
        if Task.isCancelled { throw .cancelled }
        return await service.requestPermission()
    }
}
