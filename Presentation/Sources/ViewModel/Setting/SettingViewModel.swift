import Core
import Domain
import Observation

@MainActor
public protocol SettingCoordinatorDelegate: AnyObject {
    /// 뒤로가기
    func pop()
}

@MainActor
@Observable
public final class SettingViewModel {
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

        Task {
            switch model {
            case .none:
                return
            case .whisper:
                try await sttRepository.download { _ in }
            case .gemma4_e2b_4bit:
                try await mlxRepository.downloadModel { _ in }
            }
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            updateModelState(model: model, newState: .downloaded)
        }
    }

    func deleteModel(model: ChaGokModel) {
        updateModelState(model: model, newState: .downloading)

        Task {
            switch model {
            case .none:
                return
            case .whisper:
                try await deleteModelRepository.whisperModel()
            case .gemma4_e2b_4bit:
                try await deleteModelRepository.mlxModel()
            }
            updateModelState(model: model, newState: .notDownloaded)
        }
    }

    private func updateModelState(model: ChaGokModel, newState: ChaGokModelState.DownloadState) {
        if let index = models.firstIndex(where: { $0.model == model }) {
            var updatedModel = models[index]
            updatedModel.isDownloaded = newState
            models[index] = updatedModel
        }
    }

    func pop() {
        coordinator?.pop()
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
        case none
    }
}
