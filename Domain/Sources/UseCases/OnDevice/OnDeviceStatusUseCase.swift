import Core
import Foundation

public protocol OnDeviceStatusUseCase: Sendable {
    /// 구독 함수
    func subscribe(model: ChaGokModel) async -> AsyncStream<OnDeviceStatus>
    /// 다운로드
    func download(model: ChaGokModel) async throws(OnDeviceStatusUseCaseError)
    /// 모델 제거
    func delete(model: ChaGokModel) async throws(DeleteOnDeviceRepositoryError)
    /// 현재 상태 조회
    func checkStatus(model: ChaGokModel) async -> OnDeviceStatus
}

public actor DefaultOnDeviceStatusUseCase: OnDeviceStatusUseCase {
    private let whisperRepository: any OnDeviceRepository
    private let mlxRepository: any OnDeviceRepository

    private var isDownloading: [ChaGokModel: Bool] = [:]
    private var latest: [ChaGokModel: OnDeviceStatus] = [:]
    private var subscribers: [UUID: (model: ChaGokModel, cont: AsyncStream<OnDeviceStatus>.Continuation)] = [:]

    public init(
        whisperRepository: any OnDeviceRepository,
        mlxRepository: any OnDeviceRepository
    ) {
        self.whisperRepository = whisperRepository
        self.mlxRepository = mlxRepository
    }

    public func subscribe(model: ChaGokModel) -> AsyncStream<OnDeviceStatus> {
        AsyncStream(bufferingPolicy: .bufferingNewest(1)) { cont in
            let id = UUID()
            Task {
                await self.syncStatus(model: model)
                await self.addSubscriber(id: id, model: model, continuation: cont)
            }

            cont.onTermination = { _ in
                Task { await self.unsubscribe(id: id) }
            }
        }
    }

    public func download(model: ChaGokModel) async throws(OnDeviceStatusUseCaseError) {
        guard let repo = repo(for: model) else { return }

        do {
            // 다운로드 시작 상태 알림
            await publish(model: model, status: OnDeviceStatus(storage: .downloading(progress: 0)))

            try await repo.download { progress in
                Task { [model] in
                    await self.publish(
                        model: model,
                        status: OnDeviceStatus(storage: .downloading(progress: progress))
                    )
                }
            }

            // 다운로드 완료 상태 알림
            await publish(model: model, status: OnDeviceStatus(storage: .downloaded))
        } catch {
            let mappedError: OnDeviceStatusUseCaseError = switch error {
            case .cancelled:
                .cancelled
            case .networkFailed:
                .networkFailed
            case .loadFailed:
                .loadFailed
            case .unknown(let underlying):
                .unknown(underlying)
            }

            AppLogger.error(mappedError)
            if case .cancelled = mappedError {
                // 사용자 취소 시 상태를 .notDownloaded로 복구하여 구독 모델들에 알림
                await publish(model: model, status: OnDeviceStatus(storage: .notDownloaded))
            } else {
                await publish(model: model, status: OnDeviceStatus(storage: .failed))
            }
            throw mappedError
        }
    }

    public func delete(model: ChaGokModel) async throws(DeleteOnDeviceRepositoryError) {
        isDownloading[model] = false
        guard let repo = repo(for: model) else { return }
        do {
            let status = try await repo.delete()
            await publish(model: model, status: status)
        } catch {
            AppLogger.error(error)
            throw error
        }
    }

    public func checkStatus(model: ChaGokModel) async -> OnDeviceStatus {
        if isDownloading[model] == true {
            return latest[model] ?? OnDeviceStatus(storage: .downloading(progress: 0.0))
        }
        if let repo = repo(for: model) {
            let status = await repo.checkStatus()
            latest[model] = status
            return status
        }
        return OnDeviceStatus(storage: .notDownloaded)
    }

    private func syncStatus(model: ChaGokModel) async {
        _ = await checkStatus(model: model)
    }

    private var lastPublishedTime: [ChaGokModel: Double] = [:]

    private func publish(model: ChaGokModel, status: OnDeviceStatus) async {
        if case .downloading(let progress) = status.storage {
            let currentTime = Date().timeIntervalSince1970
            let lastTime = lastPublishedTime[model] ?? 0.0
            if currentTime - lastTime < 0.05, progress < 1.0, progress > 0.0 {
                return
            }
            lastPublishedTime[model] = currentTime
        } else {
            lastPublishedTime[model] = nil
        }

        latest[model] = status
        for (_, item) in subscribers where item.model == model {
            item.cont.yield(status)
            AppLogger.info("📢 [UseCase] 상태 발행: \(status)")
        }
    }

    private func addSubscriber(
        id: UUID,
        model: ChaGokModel,
        continuation: AsyncStream<OnDeviceStatus>.Continuation
    ) async {
        subscribers[id] = (model, continuation)
        if let status = latest[model] {
            continuation.yield(status)
        }
    }

    private func unsubscribe(id: UUID) {
        subscribers[id]?.cont.finish()
        subscribers[id] = nil
    }

    private func repo(for model: ChaGokModel) -> (any OnDeviceRepository)? {
        switch model {
        case .whisper:
            whisperRepository
        case .gemma4_e2b_4bit:
            mlxRepository
        case .none:
            nil
        }
    }
}
