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

    // MARK: - 생성자

    public init(
        languageRepository: any LanguageRepository,
        voiceRecordRepository: any VoiceRecordRepository,
        sttRepository: any STTRepository,
        checkFirstLaunchRepository: any CheckFirstLaunchRepository,
        folderUseCase: any FolderUseCase
    ) {
        self.languageRepository = languageRepository
        self.voiceRecordRepository = voiceRecordRepository
        self.sttRepository = sttRepository
        self.checkFirstLaunchRepository = checkFirstLaunchRepository
        self.folderUseCase = folderUseCase
    }

    // MARK: - State

    private(set) var currentStep: Step = .first
    private(set) var errorMessage: String?
    private(set) var language: Language = .ko

    private var isPaging: Bool = false
    var steps: [Step] {
        Step.allCases
    }

    var primaryButtonTitle: String {
        currentStep == .finish ? "시작하기" : "다음"
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
            let nextIndex = currentStep.rawValue + 1
            guard nextIndex < Step.allCases.count else { return }
            isPaging = true
            scrollAction(nextIndex)
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
        }
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
