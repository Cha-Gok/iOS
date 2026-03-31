import Core
import Domain
import Foundation
import Observation
import UIKit

@Observable
@MainActor
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

    private var isPaging: Bool = false

    // MARK: - Setters

    func setCurrentStep(_ val: Int) {
        currentStep = Step.matchingStep(val)
    }

    func setLanguage(_ val: Language) {
        language = val
    }

    // MARK: - Getters

    func getMaxIndex() -> Int {
        Step.allCases.count
    }

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

    // MARK: - Update Button

    func updateButtonConfiguration(primaryButton: GlassButton, secondButton: UIButton) {
        switch currentStep {
        case .finish:
            primaryButton.configurationUpdateHandler = { [weak self] configuration in
                configuration.configuration?.title = self?.primaryButtonTitle
                configuration.configuration?.baseBackgroundColor = UIColor.point600
                configuration.configuration?.baseForegroundColor = UIColor.gray900
            }
            secondButton.isUserInteractionEnabled = false
        default:
            primaryButton.configurationUpdateHandler = { [weak self] configuration in
                configuration.configuration?.title = self?.primaryButtonTitle
                configuration.configuration?.baseBackgroundColor = UIColor.point200
                    .withAlphaComponent(Constant.backgroundOpacity)
                configuration.configuration?.baseForegroundColor = UIColor.gray900
            }
            secondButton.isUserInteractionEnabled = true
        }
        secondButton.configuration?.title = secondButtonTitle
    }

    func primaryButtonAction(pagingView: OnBoardingPagingView) {
        guard !isPaging else { return }
        switch currentStep {
        case .finish:
            getTest() // test 목적
            AppLogger.info("마지막 시작하기 버튼 기능이 들어가야 합니다.")
        default: // 다음
            if currentStep == .micPermission {
                // 마이크 권한 요청 로직
                print("마이크 요청을 하는가")
            }
            let nextIndex = currentStep.rawValue + 1
            guard nextIndex < Step.allCases.count else { return }
            isPaging = true
            let offsetX = CGFloat(nextIndex) * pagingView.frame.width
            pagingView.setContentOffset(CGPoint(x: offsetX, y: 0), animated: true)
        }
    }

    func secondButtonAction(pagingView: OnBoardingPagingView) {
        guard !isPaging else { return }
        switch currentStep {
        case .first: // 건너뛰기
            let nextIndex = Step.finish.rawValue
            isPaging = true
            let offsetX = CGFloat(nextIndex) * pagingView.frame.width
            pagingView.setContentOffset(CGPoint(x: offsetX, y: 0), animated: true)
        default: // 뒤로가기
            let nextIndex = currentStep.rawValue - 1
            guard nextIndex >= 0 else { return }
            isPaging = true
            let offsetX = CGFloat(nextIndex) * pagingView.frame.width
            pagingView.setContentOffset(CGPoint(x: offsetX, y: 0), animated: true)
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
        let diff = nextStep - currentStep.rawValue

        if diff > 1 {
            currentStep = currentStep.skip()
        } else if diff == 1 {
            currentStep = currentStep.next()
        } else {
            currentStep = currentStep.prev()
        }
    }

    /// first, second, micPermission 은 OnBoardingCardView로 화면 구성
    /// finish 만 다른 컴포넌트 화면을 사용합니다.
    func createPages() -> [UIView] {
        Step.allCases.map { step in
            switch step {
            case .first, .second, .micPermission:
                let item = step.item
                return OnBoardingCardView(
                    headline: item.headline,
                    body: item.body,
                    image: UIImage(named: item.image ?? "", in: Bundle(for: OnBoardingCardView.self), with: nil)
                )
            case .finish:
                let item = step.item
                return OnBoardingFinishView(
                    headline: item.headline,
                    body: item.body,
                    selectedLanguage: language,
                    onLanguageChanged: { [weak self] lang in
                        self?.setLanguage(lang)
                    }
                )
            }
        }
    }
}
