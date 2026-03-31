import Core
import Domain
import Foundation
import UIKit

public final class OnBoardingViewController: UIViewController {
    // MARK: - State

    private let vm: OnBoardingViewModel = .init()

    // MARK: - Component

    private lazy var pagenation: Pagenation = .init(
        currentIndex: vm.currentStep.rawValue,
        maxIndex: vm.getMaxIndex()
    )

    private lazy var pagingView: OnBoardingPagingView = .init(pages: vm.createPages())

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

    override public func updateProperties() {
        super.updateProperties()
        // title value 업데이트
        vm.updateTitle()
        // Button 업데이트
        vm.updateButtonConfiguration(
            primaryButton: primaryButton,
            secondButton: secondButton
        )
        // pagenation 업데이트
        pagenation.currentIndex = vm.currentStep.rawValue
        pagenation.setNeedsLayout()
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
                vm.primaryButtonAction(pagingView: pagingView)
            }, for: .touchUpInside
        )

        secondButton.addAction(
            UIAction { [weak self] _ in
                guard let self else { return }
                vm.secondButtonAction(pagingView: pagingView)
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
            pagenation.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor,
                constant: Constant.onBoardingPaginationTopMargin
            ),
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

// MARK: - UIScrollViewDelegate

extension OnBoardingViewController: UIScrollViewDelegate {
    /// 사용자가 손으로 스와이프해서 멈췄을 때
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let nextStep = Int(round(scrollView.contentOffset.x / scrollView.frame.width))
        vm.syncPageState(nextStep: nextStep)
    }

    /// setContentOffset(animated: true)로 코드 스크롤이 끝났을 때
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        let nextStep = Int(round(scrollView.contentOffset.x / scrollView.frame.width))
        vm.syncPageState(nextStep: nextStep)
    }
}

#Preview {
    OnBoardingViewController()
}
