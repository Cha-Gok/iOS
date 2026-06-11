import Core
import Domain
import Foundation

@MainActor
public protocol DownloadOnDeviceCoordinatorDelegate: AnyObject {
    /// 시트를 닫습니다
    /// - Parameter completion: true: 다운로드 완료 / false: 취소 또는 나중에
    func dismissSheet()
}

@MainActor
@Observable
public final class DownloadOnDeviceViewModel {
    // MARK: - State

    /// 온디바이스 모델의 통합 상태값
    private(set) var status: OnDeviceStatus = .init(storage: .notDownloaded)
    private(set) var errorMessage: String?
    private(set) var modelSize: String = ""

    public weak var coordinator: DownloadOnDeviceCoordinatorDelegate?
    private let onDeviceStatusUseCase: any OnDeviceStatusUseCase

    @ObservationIgnored
    private var statusObservationTask: Task<Void, Never>?
    @ObservationIgnored
    private var downloadTask: Task<Void, Never>?

    /// UI Binding을 위해 status로부터 파생된 연산 프로퍼티들
    var isDownloading: Bool {
        if case .downloading = status.storage { return true }
        return false
    }

    // MARK: - Initialize

    public init(
        onDeviceStatusUseCase: any OnDeviceStatusUseCase
    ) {
        self.onDeviceStatusUseCase = onDeviceStatusUseCase
        onAppearSize()
        observeDownloadStatus()
    }
}

// MARK: - Actions

extension DownloadOnDeviceViewModel {
    /// 모델 다운로드 용량 크기를 가져옵니다.
    func onAppearSize() {
        Task {
            modelSize = await onDeviceStatusUseCase.fetchModelSize(model: .whisper)
        }
    }

    /// 온디바이스 모델(Whisper)의 상태 스트림을 구독하여 상태를 관찰합니다.
    private func observeDownloadStatus() {
        statusObservationTask?.cancel()
        statusObservationTask = Task { [weak self] in
            guard let self else { return }
            let stream = await onDeviceStatusUseCase.subscribe(model: .whisper)
            for await newStatus in stream {
                status = newStatus
                AppLogger.debug("OnDeviceStatus: \(newStatus)")
                if newStatus.storage == .downloaded {
                    dismiss()
                }
            }
        }
    }

    /// 모델의 다운로드를 유즈케이스에 요청합니다.
    func download() {
        guard downloadTask == nil else { return }
        errorMessage = nil

        downloadTask = Task {
            defer { downloadTask = nil }
            do {
                try await onDeviceStatusUseCase.download(model: .whisper)
            } catch {
                // 사용자 명시적 취소(.cancelled)인 경우 에러 메시지를 표시하지 않고 무시
                if case .cancelled = error as? OnDeviceStatusUseCaseError {
                    return
                }
                self.errorMessage = error.localizedDescription
            }
        }
    }

    func cancelDownload() {
        let task = downloadTask
        downloadTask = nil
        status = OnDeviceStatus(storage: .notDownloaded)

        let useCase = onDeviceStatusUseCase
        Task {
            task?.cancel()
            try? await useCase.delete(model: .whisper)
        }
    }

    func dismiss() {
        statusObservationTask?.cancel()

        let task = downloadTask
        downloadTask = nil

        // 다운로드가 완전히 완료되지 않은 상태(예: 취소 상태)에서 해제될 때만
        // 유즈케이스의 저장 캐시 및 디스크 상태를 완전히 초기화(notDownloaded)합니다.
        if status.storage != .downloaded {
            let useCase = onDeviceStatusUseCase
            Task {
                task?.cancel()
                try? await useCase.delete(model: .whisper)
            }
        } else {
            task?.cancel()
        }
        coordinator?.dismissSheet()
    }
}
