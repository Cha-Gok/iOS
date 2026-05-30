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
    private let languageRepository: any LanguageRepository
    private let availableModelRepository: any AvailableModelSupportRepository
    private let onDeviceStatusUseCase: any OnDeviceStatusUseCase

    public weak var coordinator: SettingCoordinatorDelegate?

    // MARK: - State

    private(set) var language: Language
    private(set) var models: [ChaGokModelState] = []

    public init(
        languageRepository: any LanguageRepository,
        availableModelRepository: any AvailableModelSupportRepository,
        onDeviceStatusUseCase: any OnDeviceStatusUseCase
    ) {
        self.languageRepository = languageRepository
        self.availableModelRepository = availableModelRepository
        self.onDeviceStatusUseCase = onDeviceStatusUseCase
        language = languageRepository.fetchLanguage()
    }

    private var observationTasks: [ChaGokModel: Task<Void, Never>] = [:]

    // MARK: - Setter / Getter

    func setLanguage(_ lang: Language) {
        language = lang
        languageRepository.saveLanguage(lang)
    }

    // MARK: - Actions

    func checkModels() {
        Task {
            self.models = await availableModelRepository.fetchSupportModels()
            observeDownloadStatus()
        }
    }

    func downloadModel(model: ChaGokModel) {
        guard model != .none else { return }
        Task {
            do {
                try await onDeviceStatusUseCase.download(model: model)
            } catch {
                AppLogger.error(error)
            }
        }
    }

    func deleteModel(model: ChaGokModel) {
        guard model != .none else { return }
        Task {
            do {
                try await onDeviceStatusUseCase.delete(model: model)
            } catch {
                AppLogger.error(error)
            }
        }
    }

    func pop() {
        coordinator?.pop()
    }

    func pushTermsOfUse() {
        coordinator?.pushTermsOfUseView()
    }

    func pushPrivacyPolicy() {
        coordinator?.pushPrivacyPolicyView()
    }

    // MARK: - Private Observation

    private func observeDownloadStatus() {
        for task in observationTasks.values {
            task.cancel()
        }
        observationTasks.removeAll()

        for modelState in models {
            let model = modelState.model
            guard model != .none else { continue }

            observationTasks[model] = Task { [weak self] in
                let stream = await self?.onDeviceStatusUseCase.subscribe(model: model)
                guard let stream else { return }
                for await newStatus in stream {
                    self?.updateModelStatus(model: model, status: newStatus)
                }
            }
        }
    }

    private func updateModelStatus(model: ChaGokModel, status: OnDeviceStatus) {
        if let index = models.firstIndex(where: { $0.model == model }) {
            models[index].status = status
        }
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
