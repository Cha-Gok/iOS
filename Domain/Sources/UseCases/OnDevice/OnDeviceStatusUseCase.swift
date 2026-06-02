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

    /// 모델별 현재 활성 다운로드 Task 및 식별자
    private var downloadTasks: [ChaGokModel: Task<Void, any Error>] = [:]
    private var downloadIDs: [ChaGokModel: UUID] = [:]

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

        // 기존 다운로드가 있으면 취소
        downloadTasks[model]?.cancel()
        downloadTasks[model] = nil

        let downloadID = UUID()
        downloadIDs[model] = downloadID
        isDownloading[model] = true

        await publish(model: model, status: OnDeviceStatus(storage: .downloading(progress: 0)))

        // 취소 가능한 내부 Task로 감싸서 관리
        let task = Task<Void, any Error> {
            try await repo.download { progress in
                Task { [model, downloadID] in
                    // 이 다운로드가 아직 활성 상태인 경우에만 progress 발행
                    guard await self.downloadIDs[model] == downloadID else { return }
                    await self.publish(
                        model: model,
                        status: OnDeviceStatus(storage: .downloading(progress: progress))
                    )
                }
            }
        }
        downloadTasks[model] = task

        do {
            try await task.value

            // 이 다운로드가 아직 활성 상태인 경우에만 완료 처리
            guard downloadIDs[model] == downloadID else { return }
            downloadTasks[model] = nil
            isDownloading[model] = false
            await publish(model: model, status: OnDeviceStatus(storage: .downloaded))
        } catch {
            // 이 다운로드가 이미 교체된 경우(새 다운로드가 시작됨) 조용히 종료
            guard downloadIDs[model] == downloadID else {
                throw .cancelled
            }
            downloadTasks[model] = nil
            isDownloading[model] = false

            let mappedError: OnDeviceStatusUseCaseError
            if error is CancellationError {
                mappedError = .cancelled
            } else if let repoError = error as? OnDeviceRepositoryError {
                mappedError = switch repoError {
                case .cancelled:
                    .cancelled
                case .networkFailed:
                    .networkFailed
                case .loadFailed:
                    .loadFailed
                case .unknown(let underlying):
                    .unknown(underlying)
                }
            } else {
                mappedError = .unknown(error)
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
        // 진행 중인 다운로드 취소
        downloadTasks[model]?.cancel()
        downloadTasks[model] = nil
        downloadIDs[model] = nil
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
        // 취소/삭제 후 남아있는 progress 콜백이 .downloading을 다시 발행하는 것을 방지
        if case .downloading = status.storage, isDownloading[model] != true {
            return
        }

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

