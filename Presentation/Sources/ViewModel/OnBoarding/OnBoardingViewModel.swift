import Domain
import Foundation
import Observation

@Observable
final class OnBoardingViewModel {
    // MARK: - UseCase

    //  let fetchLanguageUseCase: FetchLanguageUseCase
    //  let selectLanguageUseCase: SelectLanguageUseCase
    //  let requestMicrophonePermissionUseCase: RequestMicrophonePermissionUseCase

    // MARK: - 생성자

    //  init(
//    fetchLanguageUseCase: FetchLanguageUseCase,
//    selectLanguageUseCase: SelectLanguageUseCase,
//    requestMicrophonePermissionUseCase: RequestMicrophonePermissionUseCase
    //  ) {
//    self.fetchLanguageUseCase = fetchLanguageUseCase
//    self.selectLanguageUseCase = selectLanguageUseCase
//    self.requestMicrophonePermissionUseCase = requestMicrophonePermissionUseCase
    //  }

    // MARK: - State

    private(set) var currentStep: Step = .first

    private(set) var primaryButtonTitle: String = "다음"

    private(set) var secondButtonTitle: String = "건너뛰기"

    private(set) var language: Language = .ko

    // MARK: - Setters

    func setCurrentStep(_ val: Int) {
        currentStep = Step.matchingStep(val)
    }

    func setLanguage(_ val: Language) {
        language = val
    }

    // MARK: - Getters

    func updateTitle() {
        switch currentStep {
        case .first:
            primaryButtonTitle = "다음"
            secondButtonTitle = "건너뛰기"
        case .second:
            secondButtonTitle = "이전"
        case .finish:
            primaryButtonTitle = "시작하기"
            secondButtonTitle = ""
        default:
            primaryButtonTitle = "다음"
            secondButtonTitle = "이전"
        }
    }

    func getTest() {
        debugPrint("currentStep: \(currentStep)")
        debugPrint("language: \(language)")
    }
}
