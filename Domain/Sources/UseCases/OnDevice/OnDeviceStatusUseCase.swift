import Core
import Foundation

public protocol OnDeviceStatusUseCase: Sendable {
    /// 구독 함수
    func subscribe(model: ChaGokModel) async -> AsyncStream<OnDeviceStatus>
    /// 다운로드
    func download(model: ChaGokModel) async throws(OnDeviceStatusUseCaseError)
    /// 모델 제거
    func delete(model: ChaGokModel) async throws(DeleteOnDeviceRepositoryError)
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
            Task { await self.addSubscriber(id: id, model: model, continuation: cont) }

            cont.onTermination = { _ in
                Task { await self.unsubscribe(id: id) }
            }
        }
    }

    public func download(model: ChaGokModel) async throws(OnDeviceStatusUseCaseError) {
        guard isDownloading[model] != true, let repo = repo(for: model) else { return }
        
        isDownloading[model] = true
        defer { isDownloading[model] = false }
        
        do {
            for try await status in repo.download() {
                try Task.checkCancellation()
                await publish(model: model, status: status)
            }
        } catch {
            let mappedError: OnDeviceStatusUseCaseError
            if error is CancellationError {
                mappedError = .cancelled
            } else if let repoError = error as? OnDeviceRepositoryError {
                switch repoError {
                case .cancelled:
                    mappedError = .cancelled
                case .networkFailed:
                    mappedError = .networkFailed
                case .loadFailed:
                    mappedError = .loadFailed
                case .unknown(let err):
                    mappedError = .unknown(err)
                }
            } else {
                mappedError = .unknown(error)
            }
            
            AppLogger.error(mappedError)
            if case .cancelled = mappedError {
                // 사용자 취소 시 상태를 .notDownloaded로 복구하여 구독 모델들에 알림
                await publish(model: model, status: OnDeviceStatus(storage: .notDownloaded, runtime: .unloaded))
            } else {
                await publish(model: model, status: OnDeviceStatus(storage: .failed, runtime: .unloaded))
            }
            throw mappedError
        }
    }

    public func delete(model: ChaGokModel) async throws(DeleteOnDeviceRepositoryError) {
        guard let repo = repo(for: model) else { return }
        do {
            let status = try await repo.delete()
            await publish(model: model, status: status)
        } catch {
            AppLogger.error(error)
            throw error
        }
    }

    private func publish(model: ChaGokModel, status: OnDeviceStatus) async {
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
