import Foundation
import Core

/// 온디바이스 다운로드 상태를 공유하기 위한 유즈케이스
public protocol OnDeviceStatusUseCase: Sendable {
    /// 구독 함수
    func subscribe(model: ChaGokModel) async -> AsyncStream<OnDeviceStatus>
    /// 다운로드
    func download(model: ChaGokModel) async
}

public actor DefaultOnDeviceStatusUseCase: OnDeviceStatusUseCase {
    private let whisperRepository: any OnDeviceRepository
    private let mlxRepository: any OnDeviceRepository
    
    private var tasks: [ChaGokModel: Task<Void, Never>] = [:]
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

    public func download(model: ChaGokModel) {
        guard tasks[model] == nil, let repo = repo(for: model) else { return }
        tasks[model] = Task {
            defer { Task { await self.clearTask(model: model) } }
            do {
                for try await status in repo.download() {
                    await publish(model: model, status: status)
                }
            } catch {
                AppLogger.error(error)
                await publish(model: model, status: OnDeviceStatus(storage: .failed, runtime: .unloaded))
            }
        }
    }

    private func publish(model: ChaGokModel, status: OnDeviceStatus) async {
        latest[model] = status
        for (_, item) in subscribers where item.model == model {
            item.cont.yield(status)
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

    private func clearTask(model: ChaGokModel) async {
        tasks[model] = nil
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
