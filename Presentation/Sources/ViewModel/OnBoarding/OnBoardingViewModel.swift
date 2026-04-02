import Core
import Domain
import Foundation
import Observation

@Observable
@MainActor
public final class OnBoardingViewModel {
    // MARK: - UseCase

    let selectLanguageUseCase: SelectLanguageUseCase
    let checkMicrophonePermissionUseCase: CheckMicrophonePermissionUseCase
    let requestMicrophonePermissionUseCase: RequestMicrophonePermissionUseCase
    let checkFirstLaunchUseCase: CheckFirstLaunchUseCase

    // MARK: - 생성자

    public init(
        selectLanguageUseCase: SelectLanguageUseCase,
        checkMicrophonePermissionUseCase: CheckMicrophonePermissionUseCase,
        requestMicrophonePermissionUseCase: RequestMicrophonePermissionUseCase,
        checkFirstLaunchUseCase: CheckFirstLaunchUseCase
    ) {
        self.selectLanguageUseCase = selectLanguageUseCase
        self.checkMicrophonePermissionUseCase = checkMicrophonePermissionUseCase
        self.requestMicrophonePermissionUseCase = requestMicrophonePermissionUseCase
        self.checkFirstLaunchUseCase = checkFirstLaunchUseCase
    }

    // MARK: - Routing

    public var onFinishOnBoarding: (() -> Void)?

    // MARK: - State

    private(set) var currentStep: Step = .first

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

    private(set) var language: Language = .ko

    private var isPaging: Bool = false

    // MARK: - Setters

    func setLanguage(_ val: Language) {
        language = val
    }

    // MARK: - Getters

    func getMaxIndex() -> Int {
        Step.allCases.count
    }

    func primaryButtonAction(scrollAction: (Int) -> Void) {
        guard !isPaging else { return }
        switch currentStep {
        case .finish:
            Task {
                await finishOnBoarding()
                _ = checkFirstLaunchUseCase.execute() // 기존 사용자 전환
                // 모든 완료 작업이 끝났으므로 해당 클로저를 호출해 화면 전환을 알립니다.
                onFinishOnBoarding?()
            }

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
            let nextIndex = Step.finish.rawValue
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
            // 마이크 권한 요청 로직
            Task {
                await requestPermission()
            }
        }
    }
}

// MARK: - UseCase 비동기 함수

extension OnBoardingViewModel {
    func requestPermission() async {
        do {
            let status: PermissionStatus = try await checkMicrophonePermissionUseCase.execute()
            if status == .notDetermined {
                _ = try await requestMicrophonePermissionUseCase.execute()
            }
        } catch {
            AppLogger.error(error)
        }
    }

    func finishOnBoarding() async {
        do {
            try await selectLanguageUseCase.execute(lang: language)
        } catch {
            AppLogger.error(error)
        }
    }
}
