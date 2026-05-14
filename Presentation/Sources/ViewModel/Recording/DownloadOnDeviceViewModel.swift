import Core
import Domain
import Foundation

@MainActor
public protocol DownloadOnDeviceCoordinatorDelegate: AnyObject {
    /// 시트를 닫습니다
    /// - Parameter completion: true: 다운로드 완료 / false: 취소 또는 나중에
    func dismissSheet(completion: Bool)
}

@MainActor
@Observable
public final class DownloadOnDeviceViewModel {
    // MARK: - State

    private(set) var progressFraction: Double?
    private(set) var isDownloading: Bool = false
    private(set) var errorMessage: String?

    public weak var coordinator: DownloadOnDeviceCoordinatorDelegate?
    private let repository: any STTRepository
    @ObservationIgnored
    private var downloadTask: Task<Void, Never>?
    @ObservationIgnored
    var progressPercentText: String {
        guard let fraction = progressFraction else { return "0%" }
        return "\(Int((fraction * 100).rounded()))%"
    }

    // MARK: - Initialize

    public init(
        repository: any STTRepository
    ) {
        self.repository = repository
    }
}

// MARK: - Actions

extension DownloadOnDeviceViewModel {
    /// 모델의 다운로드를 진행 하며 현재 상태를 handler를 통해 반환합니다.
    func download() {
        guard downloadTask == nil else { return }

        downloadTask = Task { [weak self] in
            guard let self else { return }
            isDownloading = true
            do {
                _ = try await repository.download { [weak self] progress in
                    Task { @MainActor [weak self] in
                        self?.progressFraction = progress.fractionCompleted
                    }
                }
            } catch let error as STTRepositoryError {
                switch error {
                case .cancelled:
                    self.progressFraction = nil
                default:
                    AppLogger.error(error)
                    self.errorMessage = error.localizedDescription
                    self.progressFraction = nil
                }
            } catch {
                AppLogger.error(error)
                errorMessage = error.localizedDescription
                progressFraction = nil
            }
            downloadTask = nil
            isDownloading = false
            dismiss()
        }
    }

    func dismissError() {
        errorMessage = nil
    }

    func cancelDownload() {
        downloadTask?.cancel()
        downloadTask = nil
        isDownloading = false
        progressFraction = nil
    }

    func dismiss() {
        let condition: Bool = !isDownloading && progressFraction == 1
        coordinator?.dismissSheet(completion: condition)
    }
}
