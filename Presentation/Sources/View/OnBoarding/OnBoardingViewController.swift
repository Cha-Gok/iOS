import Core
import Domain
import Foundation
import UIKit

public final class OnBoardingViewController: UIViewController {
    // MARK: - State

    private let vm: OnBoardingViewModel = .init()

    // MARK: - Component

    private lazy var pagenation: Pagenation = .init(
        currentIndex: vm.currentStep.rawValue
    )

    private lazy var pagingView: OnBoardingPagingView = .init(pages: createPages())

    private lazy var primaryButton: GlassButton = .default(vm.primaryButtonTitle)

    private lazy var secondButton: UIButton = {
        let btn = UIButton()
        btn.translatesAutoresizingMaskIntoConstraints = false
        var config: UIButton.Configuration = .plain()
        config.title = vm.secondButtonTitle
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = Typography.body3.font
            return outgoing
        }
        config.baseForegroundColor = UIColor.gray750
        config.baseBackgroundColor = .clear
        btn.configuration = config
        return btn
    }()

    // MARK: - LifeCycle

    override public func viewDidLoad() {
        super.viewDidLoad()
        setup()
        setupPagenation()
        setupCard()
        setupButtons()
    }

    override public func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        primaryButton.configuration?.title = vm.primaryButtonTitle
        secondButton.configuration?.title = vm.secondButtonTitle
        if vm.currentStep == .finish {
            primaryButton.configure(
                vm.primaryButtonTitle,
                typography: .subtitle1,
                backgroundColor: UIColor.point600,
                foregroundColor: .white
            )
            secondButton.isUserInteractionEnabled = false
        } else {
            primaryButton.configure(
                vm.primaryButtonTitle,
                typography: .subtitle1,
                border: GlassButton.Border(color: UIColor.gray600, width: Constant.borderWidth),
                backgroundColor: UIColor.point200.withAlphaComponent(Constant.backgroundOpacity),
                foregroundColor: UIColor.gray900
            )
            secondButton.isUserInteractionEnabled = true
        }
        guard vm.currentStep == .micPermission else { return }
        // 마이크 권한 요청 로직
        print("마이크 요청을 하는가")
    }

    override public func updateProperties() {
        super.updateProperties()
        // title value 업데이트
        vm.updateTitle()
    }

    // MARK: - Set up

    private func setup() {
        view.backgroundColor = UIColor.gray50
        // scroll delegate
        pagingView.delegate = self
        // 모든 뷰를 먼저 계층 구조에 추가 (제약 조건 충돌 방지)
        view.addSubview(pagenation)
        view.addSubview(pagingView)
        view.addSubview(primaryButton)
        view.addSubview(secondButton)
    }

    private func setupPagenation() {
        setupPagenationConstraint()
    }

    private func setupCard() {
        setupCardConstraint()
    }

    private func setupButtons() {
        setupButtonConstraint()
        // 버튼은 스크롤만 시킴 → 상태 업데이트는 delegate에서 처리
        primaryButton.addAction(
            UIAction { [weak self] _ in
                guard let self else { return }
                switch vm.currentStep {
                case .finish:
                    vm.getTest() // test 목적
                    AppLogger.info("마지막 시작하기 버튼 기능이 들어가야 합니다.")
                default: // 다음
                    let nextIndex = vm.currentStep.rawValue + 1
                    guard nextIndex < Step.allCases.count else { return }
                    let offsetX = CGFloat(nextIndex) * pagingView.frame.width
                    pagingView.setContentOffset(CGPoint(x: offsetX, y: 0), animated: true)
                }
            }, for: .touchUpInside
        )

        secondButton.addAction(
            UIAction { [weak self] _ in
                guard let self else { return }
                switch vm.currentStep {
                case .first: // 건너뛰기
                    let nextIndex = Step.finish.rawValue
                    let offsetX = CGFloat(nextIndex) * pagingView.frame.width
                    pagingView.setContentOffset(CGPoint(x: offsetX, y: 0), animated: true)
                default: // 뒤로가기
                    let nextIndex = vm.currentStep.rawValue - 1
                    guard nextIndex < Step.allCases.count else { return }
                    let offsetX = CGFloat(nextIndex) * pagingView.frame.width
                    pagingView.setContentOffset(CGPoint(x: offsetX, y: 0), animated: true)
                }
            }, for: .touchUpInside
        )
    }

    // MARK: - Constraint

    private func setupCardConstraint() {
        NSLayoutConstraint.activate([
            // 페이징 뷰 위치 제약 (페이지네이션과 다음 버튼 사이)
            pagingView.topAnchor.constraint(
                equalTo: pagenation.bottomAnchor,
                constant: Constant.onBoardingPagingViewTopMargin
            ),
            pagingView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: Constant.onBoardingHorizontalPadding
            ),
            pagingView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -Constant.onBoardingHorizontalPadding
            ),
            pagingView.bottomAnchor.constraint(
                equalTo: primaryButton.topAnchor,
                constant: -Constant.onBoardingPagingViewBottomMargin
            )
        ])
    }

    private func setupPagenationConstraint() {
        NSLayoutConstraint.activate([
            pagenation.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            pagenation.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: Constant.onBoardingHorizontalPadding
            ),
            pagenation.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -Constant.onBoardingHorizontalPadding
            )
        ])
    }

    private func setupButtonConstraint() {
        NSLayoutConstraint.activate([
            secondButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            secondButton.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: Constant.onBoardingButtonHorizontalPadding
            ),
            secondButton.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -Constant.onBoardingButtonHorizontalPadding
            ),
            secondButton.heightAnchor.constraint(equalToConstant: Constant.commonButtonHeight),

            primaryButton.bottomAnchor.constraint(
                equalTo: secondButton.topAnchor,
                constant: -Constant.onBoardingButtonSpacing
            ),
            primaryButton.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: Constant.onBoardingButtonHorizontalPadding
            ),
            primaryButton.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -Constant.onBoardingButtonHorizontalPadding
            ),
            primaryButton.heightAnchor.constraint(equalToConstant: Constant.commonButtonHeight)
        ])
    }
}

// MARK: - Helper

extension OnBoardingViewController {
    /// 스크롤 뷰의 현재 offset을 기준으로 currentStep과 pagenation을 동기화합니다.
    /// 스와이프(1칸)든 건너뛰기(여러 칸)든 모든 페이지 전환이 이 함수를 통해 처리됩니다.
    private func syncPageState(from scrollView: UIScrollView) {
        let newStep = Int(round(scrollView.contentOffset.x / scrollView.frame.width))
        guard newStep != vm.currentStep.rawValue else { return }

        let diff = newStep - vm.currentStep.rawValue

        if diff > 1 {
            pagenation.skip()
        } else if diff == 1 {
            pagenation.next()
        } else {
            pagenation.prev()
        }
        vm.setCurrentStep(newStep)
    }

    /// first, second, micPermission 은 OnBoardingCardView로 화면 구성
    /// finish 만 다른 컴포넌트 화면을 사용합니다.
    private func createPages() -> [UIView] {
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
                    selectedLanguage: vm.language,
                    onLanguageChanged: { [weak self] lang in
                        self?.vm.setLanguage(lang)
                    }
                )
            }
        }
    }
}

// MARK: - UIScrollViewDelegate

extension OnBoardingViewController: UIScrollViewDelegate {
    /// 사용자가 손으로 스와이프해서 멈췄을 때
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        syncPageState(from: scrollView)
    }

    /// setContentOffset(animated: true)로 코드 스크롤이 끝났을 때
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        syncPageState(from: scrollView)
    }
}

#Preview {
    OnBoardingViewController()
}
