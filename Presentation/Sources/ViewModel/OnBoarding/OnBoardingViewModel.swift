import Core
import Domain
import Foundation
import Observation

@MainActor
public protocol OnboardingCoordinatorDelegate: AnyObject {
    /// 온보딩 완료 시 화면 전환을 호출합니다.
    func finishOnBoarding()
}

@Observable
@MainActor
public final class OnBoardingViewModel {
    // MARK: - Delegate

    public weak var onBoardingCoordinator: OnboardingCoordinatorDelegate?

    // MARK: - Dependencies

    let languageRepository: any LanguageRepository
    let voiceRecordRepository: any VoiceRecordRepository
    let sttRepository: any STTRepository
    let checkFirstLaunchRepository: any CheckFirstLaunchRepository
    let folderUseCase: any FolderUseCase
    let availableSupportModelRepository: any AvailableModelSupportRepository
    let mlxRepository: any OnDeviceRepository

    // MARK: - 생성자

    public init(
        languageRepository: any LanguageRepository,
        voiceRecordRepository: any VoiceRecordRepository,
        sttRepository: any STTRepository,
        checkFirstLaunchRepository: any CheckFirstLaunchRepository,
        folderUseCase: any FolderUseCase,
        availableSupportModelRepository: any AvailableModelSupportRepository,
        mlxRepository: any OnDeviceRepository
    ) {
        self.languageRepository = languageRepository
        self.voiceRecordRepository = voiceRecordRepository
        self.sttRepository = sttRepository
        self.checkFirstLaunchRepository = checkFirstLaunchRepository
        self.folderUseCase = folderUseCase
        self.availableSupportModelRepository = availableSupportModelRepository
        self.mlxRepository = mlxRepository
    }

    // MARK: - State

    private(set) var currentStep: Step = .first
    private(set) var errorMessage: String?
    private(set) var language: Language = .ko
    private(set) var modelSupport: Bool = false
    private(set) var downloadTask: Task<Void, Never>?
    private(set) var status: OnDeviceStatus = .init(
        storage: .notDownloaded,
        runtime: .unloaded
    )
    private(set) var scrollEnabled: Bool = true

    private var isPaging: Bool = false
    private(set) var steps: [Step] = Step.allCases

    var primaryButtonTitle: String {
        switch currentStep {
        case .finish:
            return "시작하기"
        case .download:
            switch status.storage {
            case .downloading:
                return "다운로드 중입니다..."
            case .downloaded:
                return "다음"
            case .failed:
                return "재시도"
            default:
                return "다운로드"
            }
        default:
            return "다음"
        }
    }

    var secondButtonTitle: String {
        switch currentStep {
        case .first:
            return "건너뛰기"
        case .finish:
            return ""
        case .download:
            switch status.storage {
            case .downloading: return "취소"
            default: return "이전"
            }
        default:
            return "이전"
        }
    }

    var isSecondButtonEnabled: Bool {
        currentStep != .finish
    }

    var isPrimaryButtonEnabled: Bool {
        switch currentStep {
        case .download:
            switch status.storage {
            case .downloading:
                return false
            default:
                return true
            }
        default:
            return true
        }
    }

    var isPrimaryButtonBgColor: Bool {
        switch currentStep {
        case .download, .finish:
            return true
        default:
            return false
        }
    }

    // MARK: - Setters

    func setLanguage(_ val: Language) {
        language = val
    }

    // MARK: - Getters

    var currentStepIndex: Int {
        steps.firstIndex(of: currentStep) ?? 0
    }
}

// MARK: - Button Actions

extension OnBoardingViewModel {
    func primaryButtonAction(scrollAction: (Int) -> Void) {
        guard !isPaging else { return }
        switch currentStep {
        case .finish:
            isPaging = true
            finishOnBoarding()
        default: // 다음
            guard currentStep != .download else {
                switch status.storage {
                case .downloading:
                    return
                case .downloaded:
                    return nextPage(scrollAction: scrollAction)
                default:
                    return download()
                }
            }
            return nextPage(scrollAction: scrollAction)
        }
    }

    func secondButtonAction(scrollAction: (Int) -> Void) {
        guard !isPaging else { return }
        switch currentStep {
        case .first: // 건너뛰기
            let nextIndex = steps.firstIndex(of: .micPermission) ?? 0
            isPaging = true
            scrollAction(nextIndex)
        case .download:
            switch status.storage {
            case .downloading:
                // 다운로드 중일 때는 다운로드 취소
                downloadTask?.cancel()
                downloadTask = nil
            default:
                let nextIndex = currentStepIndex - 1
                guard nextIndex >= 0 else { return }
                isPaging = true
                scrollAction(nextIndex)
            }
        default: // 뒤로가기
            let nextIndex = currentStepIndex - 1
            guard nextIndex >= 0 else { return }
            isPaging = true
            scrollAction(nextIndex)
        }
    }
}

// MARK: - Download Page State

extension OnBoardingViewModel {
    /// 온보딩 진입 시 Gemma4를 지원하는 기기인지 분기합니다.
    func checkModelSupport() async {
        let support = await availableSupportModelRepository.checkMLXSupportModel()
        modelSupport = support.model == .gemma4_e2b_4bit
        steps = modelSupport ? Step.allCases : Step.allCases.filter { $0 != .download }
        if !steps.contains(currentStep) {
            currentStep = .finish
        }
    }

    private func download() {
        scrollEnabled = false
        errorMessage = nil
        downloadTask?.cancel()
        downloadTask = Task {
            defer {
                scrollEnabled = true
                if Task.isCancelled {
                    AppLogger.debug("Download Task Cancelled!!")
                    status = OnDeviceStatus(storage: .notDownloaded, runtime: .unloaded)
                }
            }
            do {
                self.status = OnDeviceStatus(storage: .downloading(progress: 0), runtime: .unloaded)
                try await mlxRepository.download { progress in
                    Task { @MainActor in
                        guard case .downloading = self.status.storage else { return }
                        self.status = OnDeviceStatus(storage: .downloading(progress: progress), runtime: .unloaded)
                    }
                }
                self.status = OnDeviceStatus(storage: .downloaded, runtime: .unloaded)
            } catch let repoError as OnDeviceRepositoryError {
                AppLogger.error(repoError)
                if case .cancelled = repoError {
                    self.status = OnDeviceStatus(storage: .notDownloaded, runtime: .unloaded)
                } else {
                    self.errorMessage = repoError.errorDescription
                    AppLogger.info(errorMessage ?? "nil")
                    self.status = OnDeviceStatus(storage: .failed, runtime: .unloaded)
                }
            } catch {
                AppLogger.error(error)
                self.errorMessage = error.localizedDescription
                self.status = OnDeviceStatus(storage: .failed, runtime: .unloaded)
            }
        }
    }
}

#if DEBUG
    public extension OnBoardingViewModel {
        /// SwiftUI Preview에서 사용할 수 있는 가상 뷰모델 인스턴스를 생성합니다.
        static func preview() -> OnBoardingViewModel {
            return OnBoardingViewModel(
                languageRepository: PreviewLanguageRepository(),
                voiceRecordRepository: PreviewVoiceRecordRepository(),
                sttRepository: PreviewSTTRepository(),
                checkFirstLaunchRepository: PreviewCheckFirstLaunchRepository(),
                folderUseCase: PreviewFolderUseCase(),
                availableSupportModelRepository: PreviewAvailableModelSupportRepository(),
                mlxRepository: PreviewOnDeviceRepository()
            )
        }
    }

    private extension OnBoardingViewModel {
        struct PreviewLanguageRepository: LanguageRepository {
            func fetchLanguage() -> Language { .ko }
            func saveLanguage(_ language: Language) {}
        }

        struct PreviewVoiceRecordRepository: VoiceRecordRepository {
            func checkMicrophonePermission() -> PermissionStatus { .authorized }
            func requestMicrophonePermission() async throws(VoiceRecordRepositoryError)
                -> PermissionStatus { .authorized }
            func startRecording() async throws(VoiceRecordRepositoryError) -> AsyncStream<Waveform> { .init { _ in } }
            func pauseRecording() async throws(VoiceRecordRepositoryError) {}
            func resumeRecording() async throws(VoiceRecordRepositoryError) {}
            func finishRecording() async throws(VoiceRecordRepositoryError) -> VoiceRecord {
                VoiceRecord(audioFilePath: "", duration: 0)
            }

            func cancelRecording() async throws(VoiceRecordRepositoryError) {}
        }

        struct PreviewSTTRepository: STTRepository {
            func transcribe(audioFilePath: String) async throws(STTRepositoryError) -> Transcript { Transcript() }
            func checkSTTPermission() -> PermissionStatus { .authorized }
            func requestSTTPermission() async throws(STTPermissionRepositoryError) -> PermissionStatus { .authorized }
        }

        struct PreviewCheckFirstLaunchRepository: CheckFirstLaunchRepository {
            func checkIsFirstLaunch() -> Bool { true }
            func checkAndMarkFirstLaunch() -> Bool { true }
        }

        struct PreviewFolderUseCase: FolderUseCase {
            func create(name: String) throws(FolderUseCaseError) -> Folder { Folder(name: name, kind: .custom) }
            func createDefault() throws(FolderUseCaseError) -> Folder { Folder(name: "기본", kind: .default) }
            func createTrash() throws(FolderUseCaseError) -> Folder { Folder(name: "휴지통", kind: .trash) }
            func fetchAll() throws(FolderUseCaseError) -> [Folder] { [] }
            func fetchDefault() throws(FolderUseCaseError) -> Folder { Folder(name: "기본", kind: .default) }
            func fetchTrash() throws(FolderUseCaseError) -> Folder { Folder(name: "휴지통", kind: .trash) }
            func fetchDeletableFolders() throws(FolderUseCaseError) -> [Folder] { [] }
            func fetch(by id: UUID) throws(FolderUseCaseError) -> Folder { Folder(name: "테스트", kind: .custom) }
            func update(_ folder: Folder) throws(FolderUseCaseError) -> Folder { folder }
            func observeCustom() throws(FolderUseCaseError) -> AsyncStream<[Folder]> { .init { _ in } }
            func observeTrashed() throws(FolderUseCaseError) -> AsyncStream<[Folder]> { .init { _ in } }
            func moveToTrash(folderID: UUID) throws(FolderUseCaseError) {}
            func restore(folderID: UUID) throws(FolderUseCaseError) {}
            func delete(folderID: UUID) throws(FolderUseCaseError) {}
        }

        struct PreviewAvailableModelSupportRepository: AvailableModelSupportRepository {
            func checkMLXSupportModel() async -> ChaGokModelSupport {
                ChaGokModelSupport(ramSizeGB: 8, isProUser: false)
            }

            func fetchSupportModels() async -> [ChaGokModelState] {
                []
            }
        }

        struct PreviewOnDeviceRepository: OnDeviceRepository {
            func checkStatus() async -> Domain.OnDeviceStatus {
                .init(storage: .downloaded, runtime: .unloaded)
            }

            func download(progressHandler: @Sendable @escaping (Double) -> Void) async throws(OnDeviceRepositoryError) {
                do {
                    // 0%에서 100%까지 0.5초 간격으로 진행률을 올려 취소를 테스트할 충분한 시간을 줍니다.
                    for progress in stride(from: 0.0, through: 1.0, by: 0.1) {
                        try await Task.sleep(nanoseconds: 500_000_000) // 0.5초 간격
                        try Task.checkCancellation()
                        progressHandler(progress)
                    }
                } catch is CancellationError {
                    throw .cancelled
                } catch {
                    throw .unknown(error)
                }
            }

            func delete() async throws(DeleteOnDeviceRepositoryError) -> OnDeviceStatus {
                OnDeviceStatus(storage: .notDownloaded, runtime: .unloaded)
            }
        }
    }
#endif

// MARK: - Delegate Helper Function

extension OnBoardingViewModel {
    /// 스크롤 뷰의 현재 offset을 기준으로 currentStep과 pagenation을 동기화합니다.
    /// 스와이프(1칸)든 건너뛰기(여러 칸)든 모든 페이지 전환이 이 함수를 통해 처리됩니다.
    func syncPageState(nextStep: Int) {
        defer { isPaging = false }
        guard steps.indices.contains(nextStep) else { return }
        let targetStep = steps[nextStep]
        guard targetStep != currentStep else { return }
        currentStep = targetStep
        if currentStep == .micPermission {
            requestPermission()
        }
    }

    private func nextPage(scrollAction: (Int) -> Void) {
        let nextIndex = currentStepIndex + 1
        guard nextIndex < steps.count else { return }
        isPaging = true
        scrollAction(nextIndex)
    }
}

// MARK: - UseCase 비동기 함수

extension OnBoardingViewModel {
    private func requestPermission() {
        Task {
            // 마이크 권한 요청
            let micStatus = voiceRecordRepository.checkMicrophonePermission()
            if micStatus == .notDetermined {
                do {
                    _ = try await voiceRecordRepository.requestMicrophonePermission()
                } catch {
                    errorMessage = error.localizedDescription
                    AppLogger.error(error)
                }
            }

            // STT 권한 요청
            let sttStatus = sttRepository.checkSTTPermission()
            if sttStatus == .notDetermined {
                do {
                    _ = try await sttRepository.requestSTTPermission()
                } catch {
                    // STT 권한 에러는 마이크 권한 에러를 덮어쓰지 않도록 함 (필요시 추가 처리 가능)
                    AppLogger.error(error)
                }
            }
        }
    }

    private func finishOnBoarding() {
        Task {
            do {
                languageRepository.saveLanguage(language)
                _ = try folderUseCase.createDefault()
                _ = try folderUseCase.createTrash()
                _ = checkFirstLaunchRepository.checkAndMarkFirstLaunch()
                onBoardingCoordinator?.finishOnBoarding()
            } catch {
                isPaging = false
                AppLogger.error(error)
                errorMessage = error.localizedDescription
            }
        }
    }
}
