import Core
import Domain
import Foundation
import UIKit

public final class OnBoardingViewController: ViewController {
    // MARK: - State

    private let vm: OnBoardingViewModel
    private var didSetupUI = false

    public init(vm: OnBoardingViewModel) {
        self.vm = vm
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    // MARK: - Component

    private lazy var pagenation: Pagenation = .init(
        currentIndex: vm.currentStepIndex,
        maxIndex: vm.steps.count
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
        Task { [weak self] in
            guard let self else { return }
            await vm.checkModelSupport()
            setup()
            setupPagenation()
            setupCard()
            setupButtons()
            didSetupUI = true
            setNeedsUpdateProperties()
        }
    }

    override public func updateProperties() {
        super.updateProperties()
        guard didSetupUI else { return }

        // 버튼 상태 업데이트
        primaryButton.configuration?.title = vm.primaryButtonTitle
        primaryButton.isHidden = !vm.isPrimaryButtonEnabled
        primaryButton.configuration?.baseBackgroundColor = vm
            .isPrimaryButtonBgColor ? UIColor.point600 : UIColor.point200
            .withAlphaComponent(Constant.backgroundOpacity)
        secondButton.configuration?.title = vm.secondButtonTitle
        secondButton.isUserInteractionEnabled = vm.isSecondButtonEnabled
        secondButton.configuration?.background.backgroundColor = vm
            .isSecondButtonBgColor ? UIColor.point600 : .clear
        secondButton.configuration?.baseForegroundColor = vm.isSecondButtonBgColor ? UIColor.gray950 : UIColor.gray750
        // paginView
        pagingView.isScrollEnabled = vm.scrollEnabled
        // pagenation 업데이트
        pagenation.currentIndex = vm.currentStepIndex
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
                vm.primaryButtonAction { index in
                    let offsetX = CGFloat(index) * pagingView.frame.width
                    pagingView.setContentOffset(CGPoint(x: offsetX, y: 0), animated: true)
                }
            }, for: .touchUpInside
        )

        secondButton.addAction(
            UIAction { [weak self] _ in
                guard let self else { return }
                vm.secondButtonAction { index in
                    let offsetX = CGFloat(index) * pagingView.frame.width
                    pagingView.setContentOffset(CGPoint(x: offsetX, y: 0), animated: true)
                }
            }, for: .touchUpInside
        )
    }

    // MARK: - Constraint

    private func setupCardConstraint() {
        let isPad = UIDevice.current.userInterfaceIdiom == .pad || UIDevice.current.model.lowercased().contains("ipad")
        let topConstant: CGFloat = isPad ? Constant.onBoardingPagingViewTopMarginForiPad : Constant
            .onBoardingPagingViewTopMargin

        NSLayoutConstraint.activate([
            // 페이징 뷰 위치 제약 (페이지네이션과 다음 버튼 사이)
            pagingView.topAnchor.constraint(
                equalTo: pagenation.bottomAnchor,
                constant: topConstant
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

// MARK: - Helper Function

extension OnBoardingViewController {
    /// first, second, micPermission 은 OnBoardingCardView로 화면 구성
    /// finish, download  만 다른 컴포넌트 화면을 사용합니다.
    private func createPages() -> [UIView] {
        vm.steps.map { step in
            switch step {
            case .first, .second, .micPermission:
                let item = step.item
                return OnBoardingCardView(
                    headline: item.headline,
                    body: item.body,
                    image: UIImage(named: item.image ?? "", in: Bundle(for: OnBoardingCardView.self), with: nil)
                )
            case .download:
                let item = step.item
                return OnBoardingDownloadView(
                    headline: item.headline,
                    body: item.body,
                    vm: vm
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
        let nextStep = Int(round(scrollView.contentOffset.x / scrollView.frame.width))
        vm.syncPageState(nextStep: nextStep)
    }

    /// setContentOffset(animated: true)로 코드 스크롤이 끝났을 때
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        let nextStep = Int(round(scrollView.contentOffset.x / scrollView.frame.width))
        vm.syncPageState(nextStep: nextStep)
    }
}

#if DEBUG
    #Preview {
        OnBoardingViewController(
            vm: .preview()
        )
    }
#endif
