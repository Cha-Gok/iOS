import Core
import Domain
import Observation

@MainActor
public protocol SettingCoordinatorDelegate: AnyObject {
    /// 뒤로가기
    func pop()
    /// 이용약관 push
    func pushTermsOfUseView()
    /// 개인정보 처리 방침 push
    func pushPrivacyPolicyView()
}

@MainActor
@Observable
public final class SettingViewModel {
    private var downloadTasks: [ChaGokModel: Task<Void, Never>] = [:]
    private let languageRepository: any LanguageRepository
    private let mlxRepository: any AvailableModelSupportRepository
    private let sttRepository: any STTRepository
    private let deleteModelRepository: any DeleteOnDeviceRepository

    public weak var coordinator: SettingCoordinatorDelegate?

    // MARK: - State

    private(set) var language: Language
    private(set) var models: [ChaGokModelState] = []

    public init(
        languageRepository: any LanguageRepository,
        mlxRepository: any AvailableModelSupportRepository,
        sttRepository: any STTRepository,
        deleteModelRepository: any DeleteOnDeviceRepository
    ) {
        self.languageRepository = languageRepository
        self.mlxRepository = mlxRepository
        self.sttRepository = sttRepository
        self.deleteModelRepository = deleteModelRepository
        language = languageRepository.fetchLanguage()
    }

    // MARK: - Setter / Getter

    func setLanguage(_ lang: Language) {
        language = lang
        languageRepository.saveLanguage(lang)
    }

    // MARK: - Actions

    func checkModels() {
        Task {
            self.models = await mlxRepository.fetchSupportModels()
        }
    }

    func downloadModel(model: ChaGokModel) {
        updateModelState(model: model, newState: .downloading)

        // Create and store a Task so it can be cancelled when the ViewModel is popped/deinitialized
        let task = Task { [weak self] in
            do {
                switch model {
                case .none:
                    return
                case .whisper:
                    try await self?.sttRepository.download { _ in }
                case .gemma4_e2b_4bit:
                    try await self?.mlxRepository.downloadModel { _ in }
                }
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                await MainActor.run {
                    self?.updateModelState(model: model, newState: .downloaded)
                }
            } catch {
                // If cancelled or failed, we simply stop; repository implementations should honor Task.isCancelled
            }
            await MainActor.run {
                self?.downloadTasks[model] = nil
            }
        }

        downloadTasks[model] = task
    }

    func deleteModel(model: ChaGokModel) {
        updateModelState(model: model, newState: .downloading)

        let task = Task { [weak self] in
            do {
                switch model {
                case .none:
                    return
                case .whisper:
                    try await self?.deleteModelRepository.whisperModel()
                case .gemma4_e2b_4bit:
                    try await self?.deleteModelRepository.mlxModel()
                }
                await MainActor.run {
                    self?.updateModelState(model: model, newState: .notDownloaded)
                }
            } catch {
                // ignore errors / cancellations
            }
            await MainActor.run {
                self?.downloadTasks[model] = nil
            }
        }

        downloadTasks[model] = task
    }

    private func updateModelState(model: ChaGokModel, newState: ChaGokModelState.DownloadState) {
        if let index = models.firstIndex(where: { $0.model == model }) {
            var updatedModel = models[index]
            updatedModel.isDownloaded = newState
            models[index] = updatedModel
        }
    }

    func pop() {
        // Cancel any in-flight download/delete tasks before popping
        let modelsToCleanup = Array(downloadTasks.keys)
        downloadTasks.values.forEach { $0.cancel() }
        downloadTasks.removeAll()

        // Immediately navigate back. Delete any partial model files in background
        // so the next `checkModels()` call reflects on-disk state.
        coordinator?.pop()

        Task {
            for model in modelsToCleanup {
                do {
                    switch model {
                    case .none:
                        break
                    case .whisper:
                        try await deleteModelRepository.whisperModel()
                    case .gemma4_e2b_4bit:
                        try await deleteModelRepository.mlxModel()
                    }
                } catch {
                    // ignore errors / cancellations
                }
            }
        }
    }

    func pushTermsOfUse() {
        coordinator?.pushTermsOfUseView()
    }

    func pushPrivacyPolicy() {
        coordinator?.pushPrivacyPolicyView()
    }
}

// MARK: - Data

extension SettingViewModel {
    enum Section: Hashable {
        case lang
        case model
        case label
    }

    struct Item: Hashable {
        let title: String
        let subTitle: String?
        let data: ItemData
    }

    enum ItemData: Hashable {
        case lang(Language)
        case model([ChaGokModelState])
        case none(LabelData)
    }

    enum LabelData: Hashable {
        case termsOfUse // 이용약관
        case privacyPolicy // 개인 정보 처리 방침
        case customerInquiry // 고객 문의
    }
}
