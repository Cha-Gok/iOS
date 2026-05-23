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
    let mlxRepository: any AvailableModelSupportRepository

    // MARK: - 생성자

    public init(
        languageRepository: any LanguageRepository,
        voiceRecordRepository: any VoiceRecordRepository,
        sttRepository: any STTRepository,
        checkFirstLaunchRepository: any CheckFirstLaunchRepository,
        folderUseCase: any FolderUseCase,
        mlxRepository: any AvailableModelSupportRepository
    ) {
        self.languageRepository = languageRepository
        self.voiceRecordRepository = voiceRecordRepository
        self.sttRepository = sttRepository
        self.checkFirstLaunchRepository = checkFirstLaunchRepository
        self.folderUseCase = folderUseCase
        self.mlxRepository = mlxRepository
    }

    // MARK: - State

    private(set) var currentStep: Step = .first
    private(set) var errorMessage: String?
    private(set) var language: Language = .ko
    private(set) var downloadStatus: DownloadStatus = .idle

    private var isPaging: Bool = false
    @ObservationIgnored
    private var downloadTask: Task<Void, Never>?
    var steps: [Step] {
        Step.allCases
    }

    var primaryButtonTitle: String {
        switch currentStep {
        case .finish:
            return "시작하기"
        case .download:
            return primaryDownloadButtonTitle
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
        default:
            return "이전"
        }
    }

    var isSecondButtonEnabled: Bool {
        currentStep != .finish
    }

    var isFinalStep: Bool {
        currentStep == .finish
    }

    // MARK: - Setters

    func setLanguage(_ val: Language) {
        language = val
    }

    // MARK: - Getters

    func getMaxIndex() -> Int {
        Step.allCases.count
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
                switch downloadStatus {
                case .checking, .downloading:
                    return
                case .completed, .notFoundModel:
                    return nextPage(scrollAction: scrollAction)
                case .idle, .failed:
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
            let nextIndex = Step.micPermission.rawValue
            isPaging = true
            scrollAction(nextIndex)
        default: // 뒤로가기
            let nextIndex = currentStep.rawValue - 1
            guard nextIndex >= 0 else { return }
            isPaging = true
            scrollAction(nextIndex)
        }
    }
}

// MARK: - Download Page State

extension OnBoardingViewModel {
    private var primaryDownloadButtonTitle: String {
        switch downloadStatus {
        case .checking:
            return "확인 중"
        case .downloading:
            return "다운로드 중"
        case .completed, .notFoundModel:
            return "다음"
        default:
            return "다운로드"
        }
    }

    @ObservationIgnored
    var modelCardIsHidden: Bool {
        switch downloadStatus {
        case .failed, .checking, .notFoundModel:
            return true
        default:
            return false
        }
    }

    var progressPercentText: String {
        let fraction = Float(downloadStatus.progress)
        return "\(Int((fraction * 100).rounded()))%"
    }

    func checkModel() {
        guard downloadStatus != .completed else { return }
        guard !downloadStatus.isDownloading else { return }
        guard downloadStatus != .checking else { return }
        downloadStatus = .checking

        Task {
            let configuration = await mlxRepository.checkSupportModel()
            switch configuration.model {
            case .none, .whisper:
                downloadStatus = .notFoundModel
            case .gemma4_e2b_4bit:
                downloadStatus = .idle
            }
        }
    }

    private func download() {
        guard downloadTask == nil else { return }
        downloadStatus = .downloading(progress: 0)
        downloadTask = Task {
            do {
                try await mlxRepository.downloadModel { [weak self] progress in
                    Task { @MainActor in
                        guard let self else { return }
                        guard self.downloadStatus != .completed else { return }
                        self.downloadStatus = .downloading(progress: progress.fractionCompleted)
                    }
                }
                downloadStatus = .completed
            } catch {
                AppLogger.error(error)
                downloadStatus = .failed(error: error.localizedDescription)
            }
            downloadTask = nil
        }
    }
}

#if DEBUG
    public extension OnBoardingViewModel {
        /// SwiftUI Preview에서 사용할 수 있는 가상 뷰모델 인스턴스를 생성합니다.
        static func preview() -> OnBoardingViewModel {
            OnBoardingViewModel(
                languageRepository: PreviewLanguageRepository(),
                voiceRecordRepository: PreviewVoiceRecordRepository(),
                sttRepository: PreviewSTTRepository(),
                checkFirstLaunchRepository: PreviewCheckFirstLaunchRepository(),
                folderUseCase: PreviewFolderUseCase(),
                mlxRepository: PreviewAvailableModelSupportRepository()
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
            func deleteWhisperModel() async throws(Domain.AvailableModelSupportRepositoryError) {}

            func deleteMLXModel() async throws(Domain.AvailableModelSupportRepositoryError) {}

            func fetchSupportModels() async -> [ChaGokModelState] {
                []
            }

            func checkSupportModel() -> ChaGokModelSupport {
                ChaGokModelSupport(ramSizeGB: 4, isProUser: false)
            }

            func downloadModel(
                progressHandler: @Sendable @escaping (Progress) -> Void
            ) async throws(AvailableModelSupportRepositoryError) {
                let progress = Progress(totalUnitCount: 100)
                for value in [10, 30, 55, 80, 100] {
                    try? await Task.sleep(nanoseconds: 250_000_000)
                    progress.completedUnitCount = Int64(value)
                    progressHandler(progress)
                }
            }

            var isModelLoaded: Bool {
                true
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
        guard nextStep != currentStep.rawValue else { return }
        currentStep = Step.matchingStep(nextStep)
        if currentStep == .micPermission {
            requestPermission()
        } else if currentStep == .download {
            checkModel()
        }
    }

    private func nextPage(scrollAction: (Int) -> Void) {
        let nextIndex = currentStep.rawValue + 1
        guard nextIndex < Step.allCases.count else { return }
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
